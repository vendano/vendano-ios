//
//  WalletService.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/3/25.
//

import Bip39
import Cardano
import CardanoBlockfrost
import Foundation

@MainActor
final class WalletService: ObservableObject {
    static let shared = WalletService()

    @Published private(set) var address: String?
    @Published private(set) var allAddresses: [String] = []

    /// Spendable ADA based on UTxOs (what Send should trust)
    @Published private(set) var adaBalance: Double = 0
    /// Optional: total ADA including staking/rewards (for expert UI)
    @Published private(set) var totalAdaBalance: Double?
    /// Optional: HOSKY balance if available in this wallet
    @Published private(set) var hoskyBalance: Double = 0

    /// “Real” sendable ADA for a *single* tx, after tokens/min-UTxO/etc.
    @Published private(set) var spendableAda: Double? = nil

    /// Last fetched UTxOs used for balances / spendable calculations.
    var currentUtxos: [TransactionUnspentOutput] = []

    @Published var adaFiatRate: Double?

    @Published var fiatCurrency: FiatCurrency = {
        if let code = UserDefaults.standard.string(forKey: "VendanoFiatCurrency"),
           let currency = FiatCurrency(rawValue: code)
        {
            return currency
        }
        return .usd
    }() {
        didSet {
            UserDefaults.standard.set(fiatCurrency.rawValue, forKey: "VendanoFiatCurrency")
        }
    }

    var cardano: Cardano?
    private var keychain: Keychain?

    private let apiBase = Config.blockfrostAPIURL
    private var bfCache = BFCache()

    private let priceService: PriceService
    private var cachedStake: String?

    private var importTask: Task<Void, Error>?
    private var txTask: Task<[RawTx], Error>?

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default

        // 20 MB in‑memory, 200 MB on disk
        config.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024,
            diskPath: "blockfrost-cache-\(Config.environmentName)"
        )

        config.requestCachePolicy = .useProtocolCachePolicy
        return URLSession(configuration: config)
    }()

    enum WalletServiceError: LocalizedError {
        case keychainNotInitialized
        case noAccountAfterFetch

        var errorDescription: String? {
            switch self {
            case .keychainNotInitialized: return L10n.WalletService.walletKeychainNotInitialized
            case .noAccountAfterFetch: return L10n.WalletService.noWalletFound
            }
        }
    }

    init(priceService: PriceService = CoinbaseService()) {
        self.priceService = priceService
    }

    func clearCache(preserveBalances: Bool = true) {
        cachedStake = nil
        if preserveBalances == false {
            adaBalance = 0
            totalAdaBalance = nil
            hoskyBalance = 0
        }
        bfCache = BFCache()
        URLCache.shared.removeAllCachedResponses()
    }

    func getJSON(_ url: Foundation.URL) async throws -> Data {
        let key = url.absoluteString

        // 1) If we have a fresh copy, just return it
        if let (freshData, _) = await bfCache.get(key) {
            return freshData
        }

        var req = URLRequest(url: url)
        req.setValue(Config.blockfrostKey, forHTTPHeaderField: "project_id")

        // 2) Peek at the stale entry to grab its ETag
        if let stale = await bfCache.peek(key),
           let tag = stale.etag
        {
            req.setValue(tag, forHTTPHeaderField: "If-None-Match")
        }

        // 3) Fire the request
        let (data, resp) = try await session.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // 4) If 304, return the stale data
        if http.statusCode == 304,
           let stale = await bfCache.peek(key)
        {
            // update fetchedAt so it becomes “fresh” again
            await bfCache.set(key, data: stale.data, etag: stale.etag)
            return stale.data
        }

        // 5) Otherwise store new payload + ETag and return it
        let etag = http.value(forHTTPHeaderField: "ETag")
        await bfCache.set(key, data: data, etag: etag)
        return data
    }

    func importWallet(words: [String], language: MnemonicLanguage? = nil) async throws {
        if let running = importTask {
            try await running.value
            return
        }

        let task = Task { [weak self] in
            guard let self else { return }
            try await self.createWallet(from: words, language: language)
        }

        importTask = task
        defer { importTask = nil }

        try await task.value
    }

    func stakeAddress(from payment: String) async throws -> String? {
        if let s = cachedStake { return s }

        struct AddrInfo: Decodable {
            let stake_address: String? // may be null for enterprise addresses
        }

        guard let url = URL(string: "\(apiBase)/addresses/\(payment)") else { throw URLError(.badURL) }
        let data = try await getJSON(url)
        let info = try JSONDecoder().decode(AddrInfo.self, from: data)

        cachedStake = info.stake_address
        return info.stake_address
    }

    func stakeBalances(stake: String) async throws -> (ada: Double, hosky: Double) {
        // ---------- ADA ----------
        struct AccountInfo: Decodable { let controlled_amount: String }

        guard let accURL = URL(string: "\(apiBase)/accounts/\(stake)") else { throw URLError(.badURL) }
        let accData = try await getJSON(accURL)
        let account = try JSONDecoder().decode(AccountInfo.self, from: accData)
        let ada = Double(UInt64(account.controlled_amount) ?? 0) / 1_000_000

        // ---------- native assets ----------
        struct AssetRow: Decodable { let unit: String; let quantity: String }

        guard let assetURL = URL(string: "\(apiBase)/accounts/\(stake)/addresses/assets?count=100") else { throw URLError(.badURL) }
        let assetData = try await getJSON(assetURL)
        let assets = try JSONDecoder().decode([AssetRow].self, from: assetData)

        // HOSKY’s full “unit” = policy‑ID + asset‑name‑hex
        let policy = "a0028f350aaabe0545fdcb56b039bfb08e4bb4d8c4d7c3c7d481c235"
        let hoskyUnit = policy + "HOSKY".hexEncoded

        let hoskyQty = assets
            .first { $0.unit == hoskyUnit }?
            .quantity ?? "0"
        let hosky = Double(hoskyQty) ?? 0

        print("⭐ ADA:", ada, "  HOSKY:", hosky)
        return (ada, hosky)
    }

    // Create (or restore) from BIP-39 words, fetch or derive the first external address, and publish it.
    func createWallet(from words: [String], language: MnemonicLanguage?) async throws {
        await bfCache.reset()

        // ✅ convert to English words for Keychain (Keychain assumes English)
        let (englishWords, usedLang) = try MnemonicCanonicalizer.toEnglishWords(words, language: language)
        print("🛠️ createWallet(): inputLang=\(language?.rawValue ?? "auto") used=\(usedLang.rawValue) count=\(words.count)")

        do {
            let keychain = try Keychain(mnemonic: englishWords)
            try keychain.addAccount(index: 0)
            self.keychain = keychain
        } catch {
            print("❌ Keychain init failed:", error)
            throw error
        }

        guard let keychain = keychain else { throw WalletServiceError.keychainNotInitialized }

        // Init Cardano + Blockfrost
        let cardano = try Cardano(
            blockfrost: Config.blockfrostKey,
            info: Config.cardanoInfo,
            signer: keychain
        )

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            cardano.addresses.fetch { result in
                switch result {
                case .success:
                    cont.resume()
                case let .failure(err):
                    cont.resume(throwing: err)
                }
            }
        }

        // Grab the account and try to get any cached addresses…
        let accounts = cardano.addresses.fetchedAccounts()
        print("⛏️ fetchedAccounts count: \(accounts.count)")
        for acct in accounts {
            print("   • account index: \(acct.index)")
        }
        guard let account = accounts.first else { throw WalletServiceError.noAccountAfterFetch }

        let cached = try cardano.addresses.get(cached: account)
        print("⛏️ cached external addresses count: \(cached.count)")

        // ...and if none, derive a brand-new one
        let addrObj: Address
        if let first = cached.first {
            addrObj = first
        } else {
            addrObj = try cardano.addresses.new(for: account, change: false)
        }

        let bech32 = try addrObj.bech32()
        print("⛏️ using first external address:", bech32)

        self.keychain = keychain
        self.cardano = cardano
        address = bech32

        await refreshBalancesFromChain()

        AnalyticsManager.logEvent("create_wallet")
    }

    // Helper to collect all UTxOs from an iterator.
    func collectAllUTXOs(
        from iterator: UtxoProviderAsyncIterator
    ) async throws -> [TransactionUnspentOutput] {
        var outs: [TransactionUnspentOutput] = []
        var next: UtxoProviderAsyncIterator? = iterator

        while let iter = next {
            let (page, following):
                ([TransactionUnspentOutput], UtxoProviderAsyncIterator?) =
                try await withCheckedThrowingContinuation { cont in
                    iter.next { result, maybeNext in
                        switch result {
                        case let .failure(err): cont.resume(throwing: err)
                        case let .success(utxos): cont.resume(returning: (utxos, maybeNext))
                        }
                    }
                }
            outs += page
            next = following
        }

        return outs
    }

    func loadPrice() async {
        do {
            let pair = fiatCurrency.pricePair // "ADA-USD", "ADA-EUR", etc.
            adaFiatRate = try await priceService.fetchPrice(for: pair)
        } catch {
            DebugLogger.log("Failed to fetch ADA price for \(fiatCurrency.rawValue): \(error.localizedDescription)")
        }
    }

    @MainActor
    func estimateNetworkFee(
        to destination: String,
        ada amount: Double,
        tip: Double
    ) async throws -> Double {
        guard let cardano = cardano else {
            throw NSError(
                domain: "Vendano",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.walletNotInitialized]
            )
        }

        let sendCoin = VendanoWalletMath.adaToLovelace(amount)

        // 👇 Tip handling should match sendMultiTransaction semantics exactly
        let tipCoin: UInt64
        if tip < 1 {
            tipCoin = 0
        } else {
            tipCoin = VendanoWalletMath.adaToLovelace(tip)
        }

        let toAddr = try CardanoCore.Address(bech32: destination)

        DebugLogger.log("💸 [fee-core] estimateNetworkFee start ada=\(amount) lovelace=\(sendCoin) dest=\(destination.prefix(20))…")

        guard let acct = cardano.addresses.fetchedAccounts().first else {
            throw NSError(
                domain: "Vendano",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.noAccountLoaded]
            )
        }

        let allAddrs = try cardano.addresses.get(cached: acct)
        guard let changeAddr = allAddrs.first else {
            throw NSError(
                domain: "Vendano",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.noPaymentAddressAvailable]
            )
        }

        let utxos: [TransactionUnspentOutput]
        if !currentUtxos.isEmpty {
            utxos = currentUtxos
            DebugLogger.log("💸 [fee-core] estimateNetworkFee using cached UTxOs count=\(utxos.count)")
        } else {
            utxos = try await collectAllUTXOs(
                from: cardano.utxos.get(for: allAddrs, asset: nil)
            )
            DebugLogger.log("💸 [fee-core] estimateNetworkFee fetched UTxOs count=\(utxos.count)")
            currentUtxos = utxos
        }

        do {
            let (_, _, feeCoin, _) = try buildCandidateTransaction(
                cardano: cardano,
                utxos: utxos,
                changeAddr: changeAddr,
                toAddr: toAddr,
                sendCoin: sendCoin,
                tipCoin: tipCoin
            )

            let feeAda = VendanoWalletMath.lovelaceToAda(feeCoin)
            DebugLogger.log("💸 [fee-core] estimateNetworkFee success feeAda=\(feeAda)")
            return feeAda
        } catch {
            DebugLogger.log("💥 [fee-core] estimateNetworkFee error: \(error)")
            if let rustError = error as? CardanoRustError, case let .common(message) = rustError {
                DebugLogger.log("💥 [fee-core] Rust error message: \(message)")
            }
            throw error
        }
    }

    func fetchTransactionsOnce(for addr: String) async throws -> [RawTx] {
        if let t = txTask {
            return try await t.value
        }
        let newTask = Task { try await fetchTransactions(for: addr) }
        txTask = newTask
        defer { txTask = nil }
        return try await newTask.value
    }

    // Fetch recent transactions for a given address via Blockfrost.
    func fetchTransactions(for addr: String) async throws -> [RawTx] {
        guard let listURL = URL(string: "\(apiBase)/addresses/\(addr)/transactions?order=desc") else { throw URLError(.badURL) }
        let listData = try await getJSON(listURL)

        struct AddressTx: Decodable { let tx_hash: String }
        let addrTxs = try JSONDecoder().decode([AddressTx].self, from: listData)
        let recentHashes = addrTxs.prefix(20).map(\.tx_hash)

        var result: [RawTx] = []

        for hash in recentHashes {
            guard let utxoURL = URL(string: "\(apiBase)/txs/\(hash)/utxos") else { throw URLError(.badURL) }
            guard let metaURL = URL(string: "\(apiBase)/txs/\(hash)") else { throw URLError(.badURL) }

            async let utxoData = getJSON(utxoURL)
            async let metaData = getJSON(metaURL)
            let (utxoBlob, metaBlob) = try await (utxoData, metaData)

            struct UTXOEntry: Decodable {
                let address: String
                let amount: [Amount]
                struct Amount: Decodable {
                    let unit: String // "lovelace"
                    let quantity: String // decimal string
                }
            }
            struct UtxoResponse: Decodable {
                let inputs: [UTXOEntry]
                let outputs: [UTXOEntry]
            }
            let utxos = try JSONDecoder().decode(UtxoResponse.self, from: utxoBlob)
            func flatten(_ entries: [UTXOEntry]) -> [(String, UInt64)] {
                entries.compactMap { e in
                    e.amount
                        .first(where: { $0.unit == "lovelace" })
                        .flatMap { UInt64($0.quantity).map { (e.address, $0) } }
                }
            }
            let inputs = flatten(utxos.inputs)
            let outputs = flatten(utxos.outputs)

            // fetch metadata for block_time

            struct TxInfo: Decodable {
                let block_time: Int
                let block_height: Int
            }

            let info = try JSONDecoder().decode(TxInfo.self, from: metaBlob)
            let date = Date(timeIntervalSince1970: TimeInterval(info.block_time))

            // print("TX \(hash) block_height=\(info.block_height) time=\(info.block_time)")

            // build and append RawTx
            result.append(.init(
                hash: hash,
                date: date,
                blockHeight: info.block_height,
                inputs: inputs,
                outputs: outputs
            ))
        }

        // already descending, but just to be safe:
        return result.sorted { $0.blockHeight > $1.blockHeight }
    }

    // MARK: – ADA Handle

    private let adaHandlePolicy = "f0ff48bbb7bbe9d59a40f1ce90e9e9d0ff5002ec48f232b49ca0fb9a"

    // 1 hour cache of resolved handles
    private var handleCache = [String: (address: String, expires: Date)]()

    func resolveAdaHandle(_ raw: String) async throws -> String? {
        var name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.hasPrefix("$") { name.removeFirst() }
        name = name.lowercased()

        if let cached = handleCache[name], cached.expires > Date() {
            return cached.address
        }

        // build Blockfrost asset unit: <policy><assetNameHex>
        let unit = adaHandlePolicy + name.hexEncoded

        struct Holder: Decodable { let address: String; let quantity: String }
        guard let url = URL(string: "\(apiBase)/assets/\(unit)/addresses?count=100&order=desc") else { throw URLError(.badURL) }

        let data = try await getJSON(url)
        let holders = try JSONDecoder().decode([Holder].self, from: data)

        // Find the first address with quantity > 0 (should be exactly one for classic handles)
        guard let holder = holders.first(where: { UInt64($0.quantity) ?? 0 > 0 }) else {
            return nil // handle exists? if not, nil
        }

        // optionally sanity-check it is a valid bech32 address
        _ = try? Address(bech32: holder.address)

        handleCache[name] = (address: holder.address, expires: Date().addingTimeInterval(3600))
        return holder.address
    }

    @MainActor
    func refreshBalancesFromChain() async {
        guard let cardano = cardano,
              let bech32 = address
        else {
            // No wallet loaded – reset balances
            adaBalance = 0
            totalAdaBalance = nil
            hoskyBalance = 0
            return
        }

        do {
            // 1) Find the account
            let accounts = cardano.addresses.fetchedAccounts()
            guard let account = accounts.first else {
                DebugLogger.log("⚠️ refreshBalancesFromChain: no account found")
                adaBalance = 0
                totalAdaBalance = nil
                hoskyBalance = 0
                return
            }

            // 2) Get all known addresses for this account
            let cached = try cardano.addresses.get(cached: account)

            // If for some reason there are none (should be rare), derive one
            let addrObj: Address
            if let first = cached.first {
                addrObj = first
            } else {
                addrObj = try cardano.addresses.new(for: account, change: false)
            }

            let allAddrs: [Address] = cached.isEmpty ? [addrObj] : cached
            allAddresses = try allAddrs.map { try $0.bech32() }

            // 3) Spendable ADA: sum lovelace from all UTxOs on all account addresses
            let utxos = try await collectAllUTXOs(
                from: cardano.utxos.get(for: allAddrs, asset: nil)
            )

            // Cache UTxOs so Home + Send share the same view of the world
            currentUtxos = utxos

            debugLogUtxos(utxos, context: "refreshBalancesFromChain")

            // Raw “on UTxOs” ADA (for debug / comparison only)
            let totalLovelace = utxos.reduce(UInt64(0)) { partial, utxo in
                partial &+ utxo.output.amount.coin
            }
            adaBalance = Double(totalLovelace) / 1_000_000
            print("⭐ [refresh] raw UTxO ADA:", adaBalance)

            // Compute max sendable using the same builder flow
            do {
                let maxLovelace = try SpendableCalculator.maxSendableLovelace(
                    cardano: cardano,
                    utxos: utxos,
                    changeAddress: addrObj,
                    destAddress: addrObj, // any valid address is fine here
                    vendanoFeeForAmount: vendanoFeeLovelace(for:),
                    tipLovelace: 0
                )

                let maxAda = Double(maxLovelace) / 1_000_000
                spendableAda = maxAda
                print("⭐ [refresh] max spendable ADA:", maxAda)
            } catch {
                DebugLogger.log("⚠️ refreshBalancesFromChain: failed to compute spendableAda: \(error)")
                spendableAda = nil
            }

            // 4) Optional: staking/rewards view for experts
            let stake = try await stakeAddress(from: bech32)
            if let stake {
                let (totalAda, hosky) = try await stakeBalances(stake: stake)
                totalAdaBalance = totalAda
                hoskyBalance = hosky
                print("⭐ [refresh] total ADA (incl. staking & rewards):", totalAda, "HOSKY:", hosky)
            } else {
                // Fall back to the same UTxO-based balance we show everywhere else
                totalAdaBalance = adaBalance
                hoskyBalance = 0
                print("⚠️ [refresh] No stake address found; using UTxO ADA as total")
            }

            await recomputeSendableAda()

        } catch {
            DebugLogger.log("⚠️ refreshBalancesFromChain failed: \(error)")
            // Don’t blow away balances on transient errors; better to keep last known values.
        }
    }

    func effectiveAppFee(for amount: Double) -> Double {
        VendanoWalletMath.vendanoFeeAda(
            forSendAda: amount,
            percent: Config.vendanoAppFeePercent
        )
    }

    @MainActor
    func recomputeSendableAda() async {
        guard let bech32 = address else {
            // ✅ Don’t clobber balances when wallet isn’t ready
            spendableAda = nil
            return
        }

        do {
            // Compute “max sendable” but do NOT overwrite adaBalance
            let max = try await maxSendableAda(to: bech32, tipAda: 0)

            // ✅ Safer: treat 0 as “unknown” so Send falls back to adaBalance
            spendableAda = (max > 0) ? max : nil

            DebugLogger.log("⭐ [wallet] recomputed spendable ADA (spendableAda): \(spendableAda?.description ?? "nil")")
        } catch {
            DebugLogger.log("⚠️ recomputeSendableAda failed: \(error)")
            spendableAda = nil
        }
    }

}

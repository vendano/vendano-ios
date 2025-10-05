//
//  WalletService.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/3/25.
//

import Cardano
import CardanoBlockfrost
import Foundation

@MainActor
final class WalletService: ObservableObject {
    static let shared = WalletService()

    @Published private(set) var address: String?
    @Published private(set) var allAddresses: [String] = []

    @Published private(set) var adaBalance: Double = 0
    @Published private(set) var hoskyBalance: Double = 0

    @Published var adaUsdRate: Double?

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

    init(priceService: PriceService = CoinbaseService()) {
        self.priceService = priceService
    }

    func clearCache(preserveBalances: Bool = true) {
        cachedStake = nil
        if preserveBalances == false {
            adaBalance = 0
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
        let http = resp as! HTTPURLResponse

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

    func importWallet(words: [String]) async throws {
        if let running = importTask {
            try await running.value
            return
        }

        let task = Task { [weak self] in
            guard let self else { return }
            try await self.createWallet(from: words)
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

        let url = URL(string: "\(apiBase)/addresses/\(payment)")!
        let data = try await getJSON(url)
        let info = try JSONDecoder().decode(AddrInfo.self, from: data)

        cachedStake = info.stake_address
        return info.stake_address
    }

    func stakeBalances(stake: String) async throws -> (ada: Double, hosky: Double) {
        // ---------- ADA ----------
        struct AccountInfo: Decodable { let controlled_amount: String }
        let accURL = URL(string: "\(apiBase)/accounts/\(stake)")!
        let accData = try await getJSON(accURL)
        let account = try JSONDecoder().decode(AccountInfo.self, from: accData)
        let ada = Double(UInt64(account.controlled_amount) ?? 0) / 1_000_000

        // ---------- native assets ----------
        struct AssetRow: Decodable { let unit: String; let quantity: String }
        let assetURL = URL(string:
            "\(apiBase)/accounts/\(stake)/addresses/assets?count=100")!
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
    func createWallet(from words: [String]) async throws {
        print("🛠️ createWallet(): word count =", words.count)

        await bfCache.reset()

        // Init keychain & ensure account #0 exists
        do {
            let keychain = try Keychain(mnemonic: words)
            try keychain.addAccount(index: 0)
            self.keychain = keychain
        } catch {
            print("❌ Keychain init failed:", error)
            throw error // rethrow so your UI still shows an error
        }

        guard let keychain = keychain else {
            fatalError("💥 Keychain init failed!")
        }

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
        guard let account = accounts.first else {
            fatalError("No account found after fetch()!")
        }

        let cached = try cardano.addresses.get(cached: account)
        print("⛏️ cached external addresses count: \(cached.count)")

        // …and if none, derive a brand-new one
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

        // Updated: stake is now optional
        let stake = try await stakeAddress(from: bech32)
        if let stake {
            print("⭐ stake address:", stake)
            let (ada, hosky) = try await stakeBalances(stake: stake)
            adaBalance = ada
            hoskyBalance = hosky
            print("⭐ total ADA:", ada, "HOSKY:", hosky)
        } else {
            print("⚠️ No stake address found for payment address, fetching ADA from UTxOs only.")

            // Fetch UTxOs for payment address to sum ADA
            struct UTXOEntry: Decodable {
                let amount: [Amount]
                struct Amount: Decodable {
                    let unit: String
                    let quantity: String
                }
            }

            let utxoURL = URL(string: "\(apiBase)/addresses/\(bech32)/utxos")!
            
            // We need to fetch the raw response and check status code for 404 before decoding
            do {
                // Use a custom fetch so we can check for 404
                var req = URLRequest(url: utxoURL)
                req.setValue(Config.blockfrostKey, forHTTPHeaderField: "project_id")
                let (data, response) = try await session.data(for: req)
                let http = response as! HTTPURLResponse

                if http.statusCode == 404 {
                    // Treat as empty UTxOs and zero balance (new address)
                    adaBalance = 0
                    hoskyBalance = 0
                    print("⭐ No UTxOs found (404) for address, setting ADA and HOSKY to zero.")
                } else {
                    do {
                        let utxos = try JSONDecoder().decode([UTXOEntry].self, from: data)

                        // Sum lovelace amounts from all UTxOs
                        let totalLovelace = utxos.reduce(UInt64(0)) { partialResult, utxo in
                            let adaAmount = utxo.amount.first(where: { $0.unit == "lovelace" })
                            let qty = UInt64(adaAmount?.quantity ?? "0") ?? 0
                            return partialResult + qty
                        }
                        adaBalance = Double(totalLovelace) / 1_000_000
                        hoskyBalance = 0
                        print("⭐ total ADA from UTxOs:", adaBalance, "HOSKY: 0")
                    } catch {
                        // Try to decode error response to check if it reports 404 status_code in JSON
                        if let decodedError = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let statusCode = decodedError["status_code"] as? Int,
                           statusCode == 404 {
                            // Treat as empty UTxOs and zero balance (new address)
                            adaBalance = 0
                            hoskyBalance = 0
                            print("⭐ No UTxOs found (404 in JSON) for address, setting ADA and HOSKY to zero.")
                        } else {
                            if let responseBody = String(data: data, encoding: .utf8) {
                                print("❌ Failed to decode UTxOs JSON with error: \(error)")
                                print("❌ Response body was: \(responseBody)")
                            } else {
                                print("❌ Failed to decode UTxOs JSON with error: \(error)")
                                print("❌ Response body could not be decoded as UTF-8 string")
                            }
                            throw error
                        }
                    }
                }
            } catch {
                // If the fetch itself fails, propagate error
                throw error
            }
        }

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
            adaUsdRate = try await priceService.fetchPrice(for: "ADA-USD")
        } catch {
            print("Failed to fetch ADA price:", error)
        }
    }

    func estimateFee(
        to destination: Address,
        lovelace amount: UInt64,
        from account: Account
    ) async throws -> UInt64 {
        print("Attempting to estimate fee to address:", destination)
        guard let c = cardano else {
            throw NSError(domain: "Vendano", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Wallet not initialized"])
        }

        return try await c.send.estimateFee(
            to: destination,
            lovelace: amount,
            from: account
        )
    }

    @MainActor
    func estimateNetworkFee(
        to destination: String,
        ada amount: Double
    ) async throws -> Double {
        guard let cardano = cardano else {
            throw NSError(domain: "Vendano", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Wallet not initialized"])
        }

        let toAddr = try Address(bech32: destination)

        let lovelace = UInt64(amount * 1_000_000)

        guard let acct = cardano.addresses.fetchedAccounts().first else {
            throw NSError(domain: "Vendano", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No account loaded"])
        }

        let feeLovelace = try await estimateFee(
            to: toAddr,
            lovelace: lovelace,
            from: acct
        )

        return Double(feeLovelace) / 1_000_000
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
        let listURL = URL(string: "\(apiBase)/addresses/\(addr)/transactions?order=desc")!
        let listData = try await getJSON(listURL)

        struct AddressTx: Decodable { let tx_hash: String }
        let addrTxs = try JSONDecoder().decode([AddressTx].self, from: listData)
        let recentHashes = addrTxs.prefix(20).map(\.tx_hash)

        var result: [RawTx] = []

        for hash in recentHashes {
            let utxoURL = URL(string: "\(apiBase)/txs/\(hash)/utxos")!
            let metaURL = URL(string: "\(apiBase)/txs/\(hash)")!

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
        let url = URL(string: "\(apiBase)/assets/\(unit)/addresses?count=100&order=desc")!
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

}


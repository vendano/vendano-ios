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
    @Published var adaUsdRate: Double?

    var cardano: Cardano?
    private var keychain: Keychain?

    private let apiBase = "https://cardano-mainnet.blockfrost.io/api/v0"
    private var bfCache = BFCache()

    private let priceService: PriceService

    init(priceService: PriceService = CoinbaseService()) {
        self.priceService = priceService
    }

    func clearCache() {
        bfCache = BFCache()
    }

    func getJSON(_ url: Foundation.URL) async throws -> Data {
        if let hit = await bfCache.get(url.absoluteString) { return hit }

        var req = URLRequest(url: url)
        req.setValue(Config.blockfrostKey, forHTTPHeaderField: "project_id")
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        await bfCache.set(url.absoluteString, data: data)
        return data
    }

    // Create (or restore) from BIP-39 words, fetch or derive the first external address, and publish it.
    func createWallet(from words: [String]) async throws {
        await bfCache.reset()

        // Init keychain & ensure account #0 exists
        let keychain = try Keychain(mnemonic: words)
        try keychain.addAccount(index: 0)

        // Init Cardano + Blockfrost
        let cardano = try Cardano(
            blockfrost: Config.blockfrostKey,
            info: .mainnet,
            signer: keychain
        )

        // Sync addresses
        _ = await withCheckedContinuation { cont in
            cardano.addresses.fetch { cont.resume(returning: $0) }
        }

        // Grab the account and try to get any cached addresses…
        guard let account = cardano.addresses.fetchedAccounts().first else {
            throw NSError(domain: "Vendano", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No account available"])
        }
        let cached = try cardano.addresses.get(cached: account) // :contentReference[oaicite:0]{index=0}

        // …and if none, derive a brand-new one
        let addrObj: Address
        if let first = cached.first {
            addrObj = first
        } else {
            addrObj = try cardano.addresses.new(for: account, change: false)
        }

        let bech32 = try addrObj.bech32()

        self.keychain = keychain
        self.cardano = cardano
        address = bech32
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

    // Fetch both ADA and HOSKY balances for `address`
    func getBalances(for addr: String) async throws -> (ada: Double, hosky: Double) {
        let url = URL(string: "\(apiBase)/addresses/\(addr)")!
        let data = try await getJSON(url)
        struct AddressInfo: Decodable { struct Amount: Decodable {
            let unit: String; let quantity: String
        }

        let amount: [Amount]
        }
        let info = try JSONDecoder().decode(AddressInfo.self, from: data)

        var ada: UInt64 = 0
        var hosky: UInt64 = 0
        let policyHex = "a0028f350aaabe0545fdcb56b039bfb08e4bb4d8c4d7c3c7d481c235"
        let hoskyUnit = policyHex + "HOSKY".hexEncoded

        for a in info.amount {
            switch a.unit {
            case "lovelace": ada = UInt64(a.quantity) ?? 0
            case hoskyUnit: hosky = UInt64(a.quantity) ?? 0
            default: break
            }
        }
        return (Double(ada) / 1_000_000, Double(hosky))
    }

    /*
     func paddedAssetName(from string: String) -> AssetName {
         var buffer = [UInt8](repeating: 0, count: 32)
         let bytes = Array(string.utf8.prefix(32)) // Max 32 bytes

         for i in 0 ..< bytes.count {
             buffer[i] = bytes[i]
         }

         let tuple = (
             buffer[0], buffer[1], buffer[2], buffer[3],
             buffer[4], buffer[5], buffer[6], buffer[7],
             buffer[8], buffer[9], buffer[10], buffer[11],
             buffer[12], buffer[13], buffer[14], buffer[15],
             buffer[16], buffer[17], buffer[18], buffer[19],
             buffer[20], buffer[21], buffer[22], buffer[23],
             buffer[24], buffer[25], buffer[26], buffer[27],
             buffer[28], buffer[29], buffer[30], buffer[31]
         )

         return AssetName(bytes: tuple, len: UInt8(bytes.count))
     }
      */

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

    // Fetch recent transactions for a given address via Blockfrost.
    func fetchTransactions(for address: String) async throws -> [RawTx] {
        let listURL = URL(string: "\(apiBase)/addresses/\(address)/transactions?order=desc")!
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
}

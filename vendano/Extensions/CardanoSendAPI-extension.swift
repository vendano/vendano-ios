//
//  CardanoSendAPI-extension.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/25/25.
//

import Cardano
import Foundation

extension CardanoSendApi {
    // Collects *all* pages from a UTxoProviderAsyncIterator
    private func collectAllPages(
        from iterator: UtxoProviderAsyncIterator
    ) async throws -> [TransactionUnspentOutput] {
        var all: [TransactionUnspentOutput] = []
        var nextIter: UtxoProviderAsyncIterator? = iterator

        while let iter = nextIter {
            let (page, following): ([TransactionUnspentOutput], UtxoProviderAsyncIterator?) =
                try await withCheckedThrowingContinuation { cont in
                    iter.next { result, maybeNext in
                        switch result {
                        case let .success(utxos):
                            print("received UTxO page of", utxos.count)
                            cont.resume(returning: (utxos, maybeNext))
                        case let .failure(err):
                            DebugLogger.log("❌ failed fetching UTxO: \(err)")
                            cont.resume(throwing: err)
                        }
                    }
                }
            all += page
            nextIter = following
        }

        return all
    }

    // Builds (but does _not_ submit) a simple ADA send tx, and returns the fee
    func estimateFee(
        to: Address,
        lovelace amount: UInt64,
        from account: Account,
        change: Address? = nil,
        maxSlots: UInt32 = 300
    ) async throws -> UInt64 {
        let cardano = self.cardano!
        let addresses = try cardano.addresses.get(cached: account)
        let changeAddr = try change ?? cardano.addresses.new(for: account, change: true)

        let slot: UInt32 = try await withCheckedThrowingContinuation { cont in
            print("getting current slot...")
            cardano.network.getSlotNumber { res in
                switch res {
                case let .success(maybeIntSlot):
                    print("✅ got slot:", maybeIntSlot ?? -1)
                    cont.resume(returning: UInt32(maybeIntSlot ?? 0))
                case let .failure(err):
                    DebugLogger.log("❌ failed to get slot: \(err)")
                    cont.resume(throwing: err)
                }
            }
        }

        let utxos = try await collectAllPages(
            from: cardano.utxos.get(for: addresses, asset: nil)
        )

        let config = TransactionBuilderConfig(
            fee_algo: cardano.info.linearFee,
            pool_deposit: cardano.info.poolDeposit,
            key_deposit: cardano.info.keyDeposit,
            max_value_size: cardano.info.maxValueSize,
            max_tx_size: cardano.info.maxTxSize,
            coins_per_utxo_word: cardano.info.coinsPerUtxoWord,
            prefer_pure_change: false
        )
        var builder = try TransactionBuilder(config: config)
        try builder.addOutput(
            output: TransactionOutput(address: to, amount: Value(coin: amount))
        )
        builder.ttl = slot + maxSlots
        try builder.addInputsFrom(inputs: utxos, strategy: .largestFirst)
        _ = try builder.addChangeIfNeeded(address: changeAddr)
        let txBody = try builder.build()

        return txBody.fee
    }
}

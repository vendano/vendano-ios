//
//  WalletService-Send.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/5/25.
//

import Cardano
import CCardano
import Foundation

@MainActor
extension WalletService {
    // Sends in one atomic transaction:
    //  1) `amount` ADA to `dest`
    //  2) the network fee as a donation to vendanoFeeAddress
    //  3) any `tip` ADA to vendanoDeveloperAddress
    func sendMultiTransaction(
        to dest: String,
        amount: Double,
        tip: Double
    ) async throws -> String {
        guard amount > 0 else {
            throw NSError(
                domain: "Vendano.Send",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Amount must be > 0"]
            )
        }
        guard tip >= 0 else {
            throw NSError(
                domain: "Vendano.Send",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Tip cannot be negative"]
            )
        }

        guard let cardano = cardano else {
            throw NSError(
                domain: "Vendano.Send",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Wallet not initialized"]
            )
        }

        guard let acct = cardano.addresses.fetchedAccounts().first else {
            throw NSError(
                domain: "Vendano.Send",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "No account loaded"]
            )
        }
        let changeAddrs = try cardano.addresses.get(cached: acct)
        let changeAddr = changeAddrs.first!

        let utxos = try await collectAllUTXOs(
            from: cardano.utxos.get(for: [changeAddr], asset: nil)
        )
        let totalLovelace = utxos.reduce(UInt64(0)) { $0 + $1.output.amount.coin }

        let info = cardano.info

        var builder = try TransactionBuilder(
            feeAlgo: info.linearFee,
            poolDeposit: BigNum(info.poolDeposit),
            keyDeposit: BigNum(info.keyDeposit),
            maxValueSize: info.maxValueSize,
            maxTxSize: info.maxTxSize,
            coinsPerUtxoWord: info.coinsPerUtxoWord,
            preferPureChange: false
        )

        try builder.addInputsFrom(inputs: utxos, strategy: .randomImprove)

        let toAddr = try CardanoCore.Address(bech32: dest)
        let sendCoin = UInt64(amount * 1_000_000)
        try builder.addOutput(
            output: TransactionOutput(
                address: toAddr,
                amount: Value(coin: sendCoin)
            )
        )

        let vendanoFeeCoin = UInt64(amount * Config.vendanoAppFeePercent * 1_000_000)
        let vendanoFeeAddr = try CardanoCore.Address(bech32: Config.vendanoFeeAddress)
        try builder.addOutput(
          output: TransactionOutput(
            address: vendanoFeeAddr,
            amount: Value(coin: vendanoFeeCoin)
          )
        )

        if tip > 0 {
            let tipCoin = UInt64(tip * 1_000_000)
            let devAddr = try CardanoCore.Address(bech32: Config.vendanoDeveloperAddress)
            try builder.addOutput(
                output: TransactionOutput(
                    address: devAddr,
                    amount: Value(coin: tipCoin)
                )
            )
        }

        let feeCoin = try builder.minFee()
        let required = sendCoin + feeCoin + vendanoFeeCoin + UInt64(tip * 1_000_000)
        guard totalLovelace >= required else {
            throw NSError(
                domain: "Vendano.Send",
                code: 4,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Insufficient funds: have \(totalLovelace), need \(required)"
                ]
            )
        }

        _ = try builder.addChangeIfNeeded(address: changeAddr)

        let txBody = try builder.build()

        let signers = try cardano.addresses
            .extended(addresses: [changeAddr])
            .map(\.address)
        let txHash = try await withCheckedThrowingContinuation { cont in
            cardano.tx.signAndSubmit(
                tx: txBody,
                with: signers,
                auxiliaryData: nil
            ) { res in
                cont.resume(with: res)
            }
        }

        let hex = txHash.hex
        return hex
    }
}

//
//  SpendableCalculator.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 12/2/25.
//
import Cardano
import CCardano
import Foundation

/// Stateless helper that uses the same TransactionBuilder flow
/// to answer: "what is the max lovelace we can send?"
enum SpendableCalculator {
    /// - Parameters:
    ///   - cardano: your Cardano instance
    ///   - utxos: UTxOs to draw from
    ///   - changeAddress: where change goes back to
    ///   - destAddress: where the main ADA output goes (any valid addr)
    ///   - vendanoFeeForAmount: closure that returns the Vendano fee for a given send amount
    ///   - tipLovelace: optional tip in lovelace
    static func maxSendableLovelace(
        cardano: Cardano,
        utxos: [CardanoCore.TransactionUnspentOutput],
        changeAddress: CardanoCore.Address,
        destAddress: CardanoCore.Address,
        vendanoFeeForAmount: (UInt64) -> UInt64,
        tipLovelace: UInt64
    ) throws -> UInt64 {
        let totalLovelace = utxos.reduce(UInt64(0)) { $0 &+ $1.output.amount.coin }
        let info = cardano.info

        func canSend(_ sendCoin: UInt64) -> Bool {
            do {
                var builder = try TransactionBuilder(
                    feeAlgo: info.linearFee,
                    poolDeposit: BigNum(info.poolDeposit),
                    keyDeposit: BigNum(info.keyDeposit),
                    maxValueSize: info.maxValueSize,
                    maxTxSize: info.maxTxSize,
                    coinsPerUtxoWord: info.coinsPerUtxoWord,
                    preferPureChange: false
                )

                // Use exactly the UTxOs we know about
                try builder.addInputsFrom(inputs: utxos, strategy: .largestFirst)

                // Main ADA output
                try builder.addOutput(
                    output: TransactionOutput(
                        address: destAddress,
                        amount: Value(coin: sendCoin)
                    )
                )

                // Vendano fee output (using the same logic as sendMultiTransaction)
                let vendanoFeeCoin = vendanoFeeForAmount(sendCoin)
                if vendanoFeeCoin > 0 {
                    let vendanoFeeAddr = try CardanoCore.Address(
                        bech32: Config.vendanoFeeAddress
                    )
                    try builder.addOutput(
                        output: TransactionOutput(
                            address: vendanoFeeAddr,
                            amount: Value(coin: vendanoFeeCoin)
                        )
                    )
                }

                // Developer tip (if any)
                if tipLovelace > 0 {
                    let devAddr = try CardanoCore.Address(
                        bech32: Config.vendanoDeveloperAddress
                    )
                    try builder.addOutput(
                        output: TransactionOutput(
                            address: devAddr,
                            amount: Value(coin: tipLovelace)
                        )
                    )
                }

                // Let the builder sort out change and fee requirements
                _ = try builder.addChangeIfNeeded(address: changeAddress)
                let feeCoin = try builder.minFee()
                DebugLogger.log("💸 builder.minFee() = \(feeCoin) lovelace (\(Double(feeCoin) / 1_000_000) ADA)")

                let required = sendCoin &+ vendanoFeeCoin &+ tipLovelace &+ feeCoin
                return required <= totalLovelace
            } catch {
                DebugLogger.log("⚠️ SpendableCalculator.canSend failed: \(error)")
                return false
            }
        }

        // Binary search for the largest sendCoin that still fits
        var low: UInt64 = 0
        var high: UInt64 = totalLovelace
        var best: UInt64 = 0

        while low <= high {
            let mid = (low &+ high) / 2
            if canSend(mid) {
                best = mid
                low = mid &+ 1
            } else {
                if mid == 0 { break }
                high = mid &- 1
            }
        }

        return best
    }
}

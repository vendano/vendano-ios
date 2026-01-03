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
    func sendMultiTransaction(
        to dest: String,
        amount: Double,
        tip: Double
    ) async throws -> String {
        guard amount > 0 else {
            throw NSError(
                domain: "Vendano.Send",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.amountMustBeGreaterThanZero]
            )
        }
        guard tip >= 0 else {
            throw NSError(
                domain: "Vendano.Send",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.tipCannotBeNegative]
            )
        }

        guard let cardano = cardano else {
            throw NSError(
                domain: "Vendano.Send",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.walletNotInitialized]
            )
        }

        guard let acct = cardano.addresses.fetchedAccounts().first else {
            throw NSError(
                domain: "Vendano.Send",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.noAccountLoaded]
            )
        }

        let allAddrs = try cardano.addresses.get(cached: acct)
        guard let changeAddr = allAddrs.first else {
            throw NSError(
                domain: "Vendano.Send",
                code: 5,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.noPaymentAddressAvailable]
            )
        }

        let utxos: [CardanoCore.TransactionUnspentOutput]
        if !currentUtxos.isEmpty {
            utxos = currentUtxos
        } else {
            utxos = try await collectAllUTXOs(
                from: cardano.utxos.get(for: allAddrs, asset: nil)
            )
            currentUtxos = utxos
        }

        debugLogUtxos(utxos, context: "sendMultiTransaction")

        let totalLovelace = utxos.reduce(UInt64(0)) { $0 + $1.output.amount.coin }

        let toAddr = try CardanoCore.Address(bech32: dest)

        let sendCoin = VendanoWalletMath.adaToLovelace(amount)

        let tipCoin: UInt64
        if tip < 1 {
            tipCoin = 0
        } else {
            tipCoin = VendanoWalletMath.adaToLovelace(tip)
        }

        let (txBody, required, feeCoin, vendanoFeeCoin) =
            try buildCandidateTransaction(
                cardano: cardano,
                utxos: utxos,
                changeAddr: changeAddr,
                toAddr: toAddr,
                sendCoin: sendCoin,
                tipCoin: tipCoin
            )

        guard totalLovelace >= required else {
            let haveAda = Double(totalLovelace) / 1_000_000
            let needAda = Double(required) / 1_000_000
            let msg = L10n.WalletService.insufficientFunds(haveAda, needAda)

            throw NSError(
                domain: "Vendano.Send",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: msg]
            )
        }

        DebugLogger.log(
            "⭐ sendMultiTransaction total=\(Double(totalLovelace) / 1_000_000) " +
                "send=\(amount) fee=\(Double(feeCoin) / 1_000_000) " +
                "vendanoFee=\(Double(vendanoFeeCoin) / 1_000_000) tip=\(tip) " +
                "required=\(Double(required) / 1_000_000)"
        )

        DebugLogger.log("💸 txBody.fee = \(txBody.fee) lovelace (\(Double(txBody.fee) / 1_000_000) ADA)")

        // 🔐 Minimal signer set: only addresses that actually hold UTxOs
        let signerBaseAddrs: [CardanoCore.Address] = {
            var seen = Set<String>()
            var result: [CardanoCore.Address] = []

            for u in utxos {
                // UTxO output address is where the coins currently live
                let bech = (try? u.output.address.bech32()) ?? ""
                guard !bech.isEmpty else { continue }
                if seen.insert(bech).inserted {
                    if let addr = try? CardanoCore.Address(bech32: bech) {
                        result.append(addr)
                    }
                }
            }

            return result
        }()

        let signers = try cardano.addresses
            .extended(addresses: signerBaseAddrs)
            .map(\.address)

        DebugLogger.log("💸 [send] signing with \(signers.count) addresses (utxo-backed)")

        let txHash = try await withCheckedThrowingContinuation { cont in
            cardano.tx.signAndSubmit(
                tx: txBody,
                with: signers,
                auxiliaryData: nil
            ) { res in
                AnalyticsManager.logEvent(
                    "sent_ada",
                    parameters: ["lovelace": required]
                )
                cont.resume(with: res)
            }
        }

        await refreshBalancesFromChain()

        return txHash.hex
    }
}

extension WalletService {
    /// Compute Vendano fee in lovelace (same as you already had)
    func vendanoFeeLovelace(for sendCoin: UInt64) -> UInt64 {
        let raw = Double(sendCoin) * Config.vendanoAppFeePercent
        let fee = UInt64(raw)

        let minUtxoLovelace: UInt64 = 1_000_000 // ≈ 1 ADA
        if fee < minUtxoLovelace {
            return 0
        }
        return fee
    }
}

extension WalletService {
    func maxSendableAda(to dest: String, tipAda: Double) async throws -> Double {
        guard let cardano = cardano else {
            throw NSError(
                domain: "Vendano.Send",
                code: 10,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.walletNotInitialized]
            )
        }

        guard let acct = cardano.addresses.fetchedAccounts().first else {
            throw NSError(
                domain: "Vendano.Send",
                code: 11,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.noAccountLoaded]
            )
        }

        let allAddrs = try cardano.addresses.get(cached: acct)
        guard let changeAddr = allAddrs.first else {
            throw NSError(
                domain: "Vendano.Send",
                code: 12,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.noPaymentAddressAvailable]
            )
        }

        let utxos = try await collectAllUTXOs(
            from: cardano.utxos.get(for: allAddrs, asset: nil)
        )

        debugLogUtxos(utxos, context: "maxSendableAda")

        let totalLovelace = utxos.reduce(UInt64(0)) { $0 &+ $1.output.amount.coin }
        if totalLovelace == 0 { return 0 }

        let toAddr = try CardanoCore.Address(bech32: dest)

        let tipCoin: UInt64
        if tipAda < 1 {
            tipCoin = 0
        } else {
            tipCoin = VendanoWalletMath.adaToLovelace(tipAda)
        }

        func canSend(_ sendCoin: UInt64) -> Bool {
            do {
                let (_, required, _, _) = try buildCandidateTransaction(
                    cardano: cardano,
                    utxos: utxos,
                    changeAddr: changeAddr,
                    toAddr: toAddr,
                    sendCoin: sendCoin,
                    tipCoin: tipCoin
                )
                return required <= totalLovelace
            } catch {
                DebugLogger.log("⚠️ maxSendableAda.canSend failed: \(error)")
                return false
            }
        }

        var low: UInt64 = 0
        var high: UInt64 = totalLovelace
        var best: UInt64 = 0

        while low <= high {
            let mid = (low + high) / 2
            if canSend(mid) {
                best = mid
                low = mid &+ 1
            } else {
                if mid == 0 { break }
                high = mid &- 1
            }
        }

        let bestAda = Double(best) / 1_000_000
        DebugLogger.log(
            "⭐ maxSendableAda total=\(Double(totalLovelace) / 1_000_000) " +
                "tip=\(tipAda) best=\(bestAda)"
        )
        return bestAda
    }
}

// MARK: - Shared Tx Builder Helper

extension WalletService {
    /// Single source of truth for building a balanced transaction and
    /// computing "required" lovelace (send + Vendano fee + tip + network fee).
    func buildCandidateTransaction(
        cardano: Cardano,
        utxos: [CardanoCore.TransactionUnspentOutput],
        changeAddr: CardanoCore.Address,
        toAddr: CardanoCore.Address,
        sendCoin: UInt64,
        tipCoin: UInt64
    ) throws -> (
        txBody: CardanoCore.TransactionBody,
        required: UInt64,
        feeCoin: UInt64,
        vendanoFeeCoin: UInt64
    ) {
        let info = cardano.info

        DebugLogger.log(
            "💸 [build] start utxos=\(utxos.count) " +
                "send=\(Double(sendCoin) / 1_000_000) " +
                "tip=\(Double(tipCoin) / 1_000_000) " +
                "linearFee=(const:\(info.linearFee.constant), coeff:\(info.linearFee.coefficient)) " +
                "coinsPerUtxoWord=\(info.coinsPerUtxoWord)"
        )

        // 🚧 Pad the fee constant so our fee is always *higher* than the node’s minimum.
        // The mismatch you’re seeing is ~13k–22k lovelace, so +50k is a safe cushion.
        let paddedLinearFee = LinearFee(
            constant: info.linearFee.constant + 50000, // +0.05 ADA
            coefficient: info.linearFee.coefficient // keep slope identical
        )

        var builder = try TransactionBuilder(
            feeAlgo: paddedLinearFee,
            poolDeposit: BigNum(info.poolDeposit),
            keyDeposit: BigNum(info.keyDeposit),
            maxValueSize: info.maxValueSize,
            maxTxSize: info.maxTxSize,
            coinsPerUtxoWord: info.coinsPerUtxoWord,
            preferPureChange: false
        )

        // Inputs
        try builder.addInputsFrom(inputs: utxos, strategy: .largestFirst)

        // Main payment output
        try builder.addOutput(
            output: TransactionOutput(
                address: toAddr,
                amount: Value(coin: sendCoin)
            )
        )

        // Vendano fee (waived < 1 ADA as before)
        let vendanoFeeCoin = vendanoFeeLovelace(for: sendCoin)
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
            DebugLogger.log(
                "💸 [build] added Vendano fee output = \(Double(vendanoFeeCoin) / 1_000_000) ADA"
            )
        } else {
            DebugLogger.log("💸 [build] Vendano fee waived for sendCoin=\(sendCoin)")
        }

        // Optional tip
        if tipCoin > 0 {
            let devAddr = try CardanoCore.Address(
                bech32: Config.vendanoDeveloperAddress
            )
            try builder.addOutput(
                output: TransactionOutput(
                    address: devAddr,
                    amount: Value(coin: tipCoin)
                )
            )
            DebugLogger.log("💸 [build] added tip output = \(Double(tipCoin) / 1_000_000) ADA")
        }

        // Balance inputs vs outputs and create change
        do {
            DebugLogger.log("💸 [build] calling addChangeIfNeeded")
            _ = try builder.addChangeIfNeeded(address: changeAddr)
        } catch {
            DebugLogger.log("💥 [build] addChangeIfNeeded threw: \(error)")
            if let rustError = error as? CardanoRustError,
               case let .common(message) = rustError
            {
                DebugLogger.log("💥 [build] addChangeIfNeeded Rust message: \(message)")
            }
            throw error
        }

        // 🔑 Canonical source of truth: the built txBody’s fee
        let txBody: CardanoCore.TransactionBody
        do {
            txBody = try builder.build()
        } catch {
            DebugLogger.log("💥 [build] builder.build() threw: \(error)")
            throw error
        }

        let feeCoin = txBody.fee
        DebugLogger.log("💸 [build] txBody.fee = \(feeCoin) lovelace (\(Double(feeCoin) / 1_000_000) ADA)")

        let required = sendCoin &+ vendanoFeeCoin &+ tipCoin &+ feeCoin

        DebugLogger.log(
            "💸 [build] required total ADA = \(Double(required) / 1_000_000) " +
                "(send=\(Double(sendCoin) / 1_000_000), fee=\(Double(feeCoin) / 1_000_000), " +
                "vendanoFee=\(Double(vendanoFeeCoin) / 1_000_000), tip=\(Double(tipCoin) / 1_000_000))"
        )

        return (txBody, required, feeCoin, vendanoFeeCoin)
    }
}

extension WalletService {
    func debugLogUtxos(_ utxos: [CardanoCore.TransactionUnspentOutput], context: String) {
        print("🔎 UTxO dump (\(context)) count=\(utxos.count)")

        for (idx, utxo) in utxos.enumerated() {
            let coin = utxo.output.amount.coin
            let ada = Double(coin) / 1_000_000

            // Very rough check: does this UTxO carry *any* native tokens?
            let hasMultiAsset = (utxo.output.amount.multiasset != nil)

            print("   [\(idx)] \(coin) lovelace (\(ada) ADA) " +
                "tokens=\(hasMultiAsset ? "yes" : "no")")
        }
    }
}

// MARK: - Store payments (store pays Vendano fee)

@MainActor
extension WalletService {
    /// Store payment where the payer pays `baseAda + tipAda`, and the Vendano fee is taken from the merchant's side
    /// (merchant receives `base - fee + tip`). Network fee is still paid by the payer (normal Cardano behavior).
    func sendStorePayment(
        to merchantAddress: String,
        baseAda: Double,
        tipAda: Double
    ) async throws -> String {
        guard baseAda > 0 else {
            throw NSError(
                domain: "Vendano.Send",
                code: 24,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.amountMustBeGreaterThanZero]
            )
        }
        guard tipAda >= 0 else {
            throw NSError(
                domain: "Vendano.Send",
                code: 25,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.tipCannotBeNegative]
            )
        }

        guard let cardano = cardano else {
            throw NSError(
                domain: "Vendano.Send",
                code: 20,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.walletNotInitialized]
            )
        }

        guard let acct = cardano.addresses.fetchedAccounts().first else {
            throw NSError(
                domain: "Vendano.Send",
                code: 21,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.noPaymentAddressAvailable]
            )
        }

        let allAddrs = try cardano.addresses.get(cached: acct)
        guard let changeAddr = allAddrs.first else {
            throw NSError(
                domain: "Vendano.Send",
                code: 23,
                userInfo: [NSLocalizedDescriptionKey: L10n.WalletService.noPaymentAddressAvailable]
            )
        }

        let utxos: [CardanoCore.TransactionUnspentOutput]
        if !currentUtxos.isEmpty {
            utxos = currentUtxos
        } else {
            let fetched = try await collectAllUTXOs(
                from: cardano.utxos.get(for: allAddrs, asset: nil)
            )
            currentUtxos = fetched
            utxos = fetched
        }

        debugLogUtxos(utxos, context: "sendStorePayment")

        let totalLovelace = utxos.reduce(UInt64(0)) { $0 + $1.output.amount.coin }

        let toAddr = try CardanoCore.Address(bech32: merchantAddress)

        let baseCoin = VendanoWalletMath.adaToLovelace(baseAda)

        // Keep prior behavior: tips under 1 ADA are waived (optional; you can remove this later)
        let tipCoin: UInt64 = tipAda < 1 ? 0 : VendanoWalletMath.adaToLovelace(tipAda)

        // Fee is calculated from the *base* amount only (tip excluded)
        let feeCoin = VendanoWalletMath.vendanoFeeLovelace(
            forSendLovelace: baseCoin,
            percent: Config.vendanoAppFeePercent
        )

        // Merchant receives base - fee + tip (fee is store-paid)
        let merchantCoin: UInt64 = (feeCoin > baseCoin ? 0 : (baseCoin - feeCoin)) + tipCoin

        let (txBody, required) = try buildCandidateTransactionStore(
            cardano: cardano,
            utxos: utxos,
            changeAddr: changeAddr,
            toAddr: toAddr,
            merchantCoin: merchantCoin,
            feeCoin: feeCoin
        )

        guard totalLovelace >= required else {
            let haveAda = Double(totalLovelace) / 1_000_000
            let needAda = Double(required) / 1_000_000
            let msg = L10n.WalletService.insufficientFunds(haveAda, needAda)
            throw NSError(
                domain: "Vendano.Send",
                code: 22,
                userInfo: [NSLocalizedDescriptionKey: msg]
            )
        }

        // 🔐 Minimal signer set: only addresses that actually hold UTxOs
        let signerBaseAddrs: [CardanoCore.Address] = {
            var seen = Set<String>()
            var result: [CardanoCore.Address] = []

            for u in utxos {
                let bech = (try? u.output.address.bech32()) ?? ""
                guard !bech.isEmpty else { continue }
                if seen.insert(bech).inserted {
                    if let addr = try? CardanoCore.Address(bech32: bech) {
                        result.append(addr)
                    }
                }
            }

            return result
        }()

        let signers = try cardano.addresses
            .extended(addresses: signerBaseAddrs)
            .map(\.address)

        DebugLogger.log("🏪 [storepay] signing with \(signers.count) addresses (utxo-backed)")

        let txHash = try await withCheckedThrowingContinuation { cont in
            cardano.tx.signAndSubmit(
                tx: txBody,
                with: signers,
                auxiliaryData: nil
            ) { res in
                cont.resume(with: res)
            }
        }

        AnalyticsManager.logEvent(
            "store_payment_sent",
            parameters: ["base_lovelace": baseCoin, "tip_lovelace": tipCoin, "fee_lovelace": feeCoin]
        )

        return txHash.hex
    }

    /// Builds a tx where merchant output is already net-of-fee, and a second output pays Vendano fee address (if feeCoin > 0).
    private func buildCandidateTransactionStore(
        cardano: Cardano,
        utxos: [CardanoCore.TransactionUnspentOutput],
        changeAddr: CardanoCore.Address,
        toAddr: CardanoCore.Address,
        merchantCoin: UInt64,
        feeCoin: UInt64
    ) throws -> (txBody: CardanoCore.TransactionBody, required: UInt64) {
        let info = cardano.info

        DebugLogger.log(
            "🏪 [storebuild] start utxos=\(utxos.count) merchant=\(Double(merchantCoin) / 1_000_000) fee=\(Double(feeCoin) / 1_000_000)"
        )

        // Keep the padded fee constant behavior from the standard send builder
        let paddedLinearFee = LinearFee(
            constant: info.linearFee.constant + 50000,
            coefficient: info.linearFee.coefficient
        )

        var builder = try TransactionBuilder(
            feeAlgo: paddedLinearFee,
            poolDeposit: BigNum(info.poolDeposit),
            keyDeposit: BigNum(info.keyDeposit),
            maxValueSize: info.maxValueSize,
            maxTxSize: info.maxTxSize,
            coinsPerUtxoWord: info.coinsPerUtxoWord,
            preferPureChange: false
        )

        try builder.addInputsFrom(inputs: utxos, strategy: .largestFirst)

        // Merchant (net) output
        try builder.addOutput(
            output: TransactionOutput(
                address: toAddr,
                amount: Value(coin: merchantCoin)
            )
        )

        // Vendano fee output (only if >= 1 ADA)
        if feeCoin >= VendanoWalletMath.minFeeOutputLovelace {
            let feeAddr = try CardanoCore.Address(bech32: Config.vendanoFeeAddress)
            try builder.addOutput(
                output: TransactionOutput(
                    address: feeAddr,
                    amount: Value(coin: feeCoin)
                )
            )
            DebugLogger.log("🏪 [storebuild] added fee output = \(Double(feeCoin) / 1_000_000) ADA")
        } else if feeCoin > 0 {
            DebugLogger.log("🏪 [storebuild] fee < min output, waived")
        }

        // Balance inputs vs outputs and create change
        do {
            _ = try builder.addChangeIfNeeded(address: changeAddr)
        } catch {
            DebugLogger.log("🏪 [storebuild] change failed: \(error.localizedDescription)")
            throw error
        }

        let txBody = try builder.build()

        // required is total output coin + tx fee (what you must have in inputs)
        let required = txBody.outputs.reduce(UInt64(0)) { $0 + $1.amount.coin } + txBody.fee

        DebugLogger.log(
            "🏪 [storebuild] done outputs=\(txBody.outputs.count) fee=\(Double(txBody.fee) / 1_000_000) required=\(Double(required) / 1_000_000)"
        )

        return (txBody: txBody, required: required)
    }
}

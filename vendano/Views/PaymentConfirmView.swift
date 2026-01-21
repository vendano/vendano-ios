//
//  PaymentConfirmView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 1/18/26.
//

import SwiftUI
import LocalAuthentication

struct PaymentConfirmView: View {
    @EnvironmentObject var theme: VendanoTheme

    @StateObject private var wallet = WalletService.shared
    @StateObject private var proximity = ProximityPaymentService.shared

    let request: VendanoPaymentRequest
    let onBack: () -> Void
    let onFinish: () -> Void

    @State private var tipText: String = ""
    @State private var isPaying = false
    @State private var netFeeAda: Double? = nil
    @State private var feeError: String? = nil

    private var tipAda: Double {
        Double(tipText) ?? 0
    }

    private var vendanoFeeAda: Double {
        let baseCoin = VendanoWalletMath.adaToLovelace(request.baseAda)
        let feeCoin = VendanoWalletMath.vendanoFeeLovelace(forSendLovelace: baseCoin, percent: Config.vendanoAppFeePercent)
        return VendanoWalletMath.lovelaceToAda(feeCoin)
    }

    private var merchantReceivesAda: Double {
        max(0, request.baseAda - vendanoFeeAda) + tipAda
    }

    private var payerTotalAda: Double {
        request.baseAda + tipAda + (netFeeAda ?? 0)
    }
    
    private var payerTotalFiatText: String? {
        guard
            let rate = wallet.adaFiatRate,
            payerTotalAda > 0
        else { return nil }

        let fiat = payerTotalAda * rate
        return "≈ \(wallet.fiatCurrency.symbol)\(fiat.formatted(.number.precision(.fractionLength(2))))"
    }

    private var payerTotalFiatFallback: String {
        L10n.StoreView.fiatApproxUnavailable
    }

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack(spacing: 18) {
                
                VStack(spacing: 10) {
                    QuickPayMatchBadge(match: request.quickPayMatch, size: 78)

                    Text(L10n.StoreView.quickPayMatchHintPayer)
                        .vendanoFont(.caption, size: 13, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed").opacity(0.85))
                        .multilineTextAlignment(.center)

                    Text(L10n.StoreView.payStoreTitle(request.storeName))
                        .vendanoFont(.headline, size: 24, weight: .bold)
                        .foregroundColor(theme.color(named: "TextReversed"))
                        .multilineTextAlignment(.center)

                    Text("\(request.baseAda.formatted(.number.precision(.fractionLength(3 ... 6)))) ADA")
                        .vendanoFont(.title, size: 40, weight: .bold)
                        .foregroundColor(theme.color(named: "TextReversed"))
                }
                .padding(.horizontal)

                VStack(spacing: 12) {
                    if request.tipsEnabled {
                        HStack {
                            Text(L10n.StoreView.addTip)
                                .vendanoFont(.body, size: 16, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextReversed"))
                            Spacer()
                            TextField("0", text: $tipText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .vendanoFont(.body, size: 16, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextReversed"))
                            Text("ADA")
                                .vendanoFont(.caption, size: 13)
                                .foregroundColor(theme.color(named: "TextReversed").opacity(0.75))
                        }
                        .padding(12)
                        .background(theme.color(named: "CellBackground").opacity(0.18))
                        .cornerRadius(14)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.StoreView.networkFee)
                            Spacer()
                            Text(netFeeAda.map { "\($0.formatted(.number.precision(.fractionLength(3 ... 6)))) ADA" } ?? L10n.StoreView.calculating)
                                .foregroundColor(theme.color(named: "TextReversed").opacity(0.75))
                        }
                        HStack {
                            Text(L10n.StoreView.vendanoFeePaidByStore(Config.vendanoAppFeePercentFormatted))
                            Spacer()
                            Text("\(vendanoFeeAda.formatted(.number.precision(.fractionLength(3 ... 6)))) ADA")
                                .foregroundColor(theme.color(named: "TextReversed").opacity(0.75))
                        }
                        HStack {
                            Text(L10n.StoreView.storeReceives)
                            Spacer()
                            Text("\(merchantReceivesAda.formatted(.number.precision(.fractionLength(3 ... 6)))) ADA")
                                .foregroundColor(theme.color(named: "TextReversed").opacity(0.75))
                        }

                        Divider().opacity(0.25)

                        HStack {
                            Text(L10n.StoreView.youPayTotal)
                                .vendanoFont(.body, size: 16, weight: .semibold)
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(payerTotalAda.formatted(.number.precision(.fractionLength(3 ... 6)))) ADA")
                                    .vendanoFont(.body, size: 16, weight: .semibold)

                                if let fiatText = payerTotalFiatText {
                                    Text(fiatText)
                                        .vendanoFont(.caption, size: 13)
                                        .foregroundColor(theme.color(named: "TextReversed").opacity(0.75))
                                } else if wallet.adaFiatRate == nil {
                                    // optional: only if you want *something* instead of nothing
                                    Text(payerTotalFiatFallback)
                                        .vendanoFont(.caption, size: 13)
                                        .foregroundColor(theme.color(named: "TextReversed").opacity(0.6))
                                }
                            }

                        }
                    }
                    .vendanoFont(.body, size: 14)
                    .foregroundColor(theme.color(named: "TextReversed"))
                    .padding(12)
                    .background(theme.color(named: "CellBackground").opacity(0.18))
                    .cornerRadius(14)

                    if let feeError {
                        Text(feeError)
                            .vendanoFont(.caption, size: 13)
                            .foregroundColor(theme.color(named: "TextReversed").opacity(0.75))
                    }

                    Button {
                        authenticateAndPay()
                    } label: {
                        Label(isPaying ? L10n.StoreView.paying : L10n.StoreView.payNow, systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(isPaying || (netFeeAda == nil))

                    Button(L10n.StoreView.cancel, role: .cancel) {
                        proximity.sendResponse(
                            VendanoPaymentResponse(
                                requestId: request.id,
                                status: .cancelled,
                                txHash: nil,
                                errorMessage: nil
                            )
                        )
                        onBack()
                    }
                    .vendanoFont(.body, size: 16)
                    .foregroundColor(theme.color(named: "TextReversed").opacity(0.85))
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .onAppear {
            Task { await estimateFee() }
        }
        .onChange(of: tipText) { _, _ in
            Task { await estimateFee() }
        }
    }

    private func estimateFee() async {
        feeError = nil

        do {
            let fee = try await wallet.estimateNetworkFee(
                to: request.merchantAddress,
                ada: request.baseAda + tipAda,
                tip: 0
            )
            netFeeAda = fee
        } catch {
            netFeeAda = nil
            feeError = error.localizedDescription
        }
    }
    
    private func authenticateAndPay() {
        guard !isPaying else { return }

        let ctx = LAContext()
        ctx.localizedCancelTitle = L10n.Common.cancelString

        var authErr: NSError?
        let policy: LAPolicy = .deviceOwnerAuthentication  // ✅ FaceID + passcode fallback

        guard ctx.canEvaluatePolicy(policy, error: &authErr) else {
            // If device can’t do FaceID/TouchID, just proceed
            Task { await payNow() }
            return
        }

        ctx.evaluatePolicy(policy, localizedReason: L10n.SendView.confirmBeforeSendingReason) { success, error in
            if success {
                Task { await payNow() }
            } else {
                Task { @MainActor in
                    // If user cancels, don’t show “error” — just stay on the screen.
                    if let laError = error as? LAError {
                        switch laError.code {
                        case .userCancel, .systemCancel, .appCancel:
                            return
                        case .biometryLockout:
                            feeError = L10n.SendView.authLockedFormat(authMethodName().capitalized)
                        default:
                            feeError = L10n.SendView.authFailed
                        }
                    } else {
                        feeError = L10n.SendView.authFailed
                    }
                }
            }
        }
    }

    private func authMethodName() -> String {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            return L10n.SendView.authPasscode
        }
        switch ctx.biometryType {
        case .faceID: return L10n.SendView.authFaceId
        case .touchID: return L10n.SendView.authTouchId
        default: return L10n.SendView.authBiometrics
        }
    }

    private func payNow() async {
        guard !isPaying else { return }
        isPaying = true

        // Signal “accepted” immediately so the merchant UI reacts
        proximity.sendResponse(
            VendanoPaymentResponse(
                requestId: request.id,
                status: .accepted,
                txHash: nil,
                errorMessage: nil
            )
        )

        do {
            let txHash = try await wallet.sendStorePayment(
                to: request.merchantAddress,
                baseAda: request.baseAda,
                tipAda: tipAda
            )

            proximity.sendResponse(
                VendanoPaymentResponse(
                    requestId: request.id,
                    status: .paid,
                    txHash: txHash,
                    errorMessage: nil
                )
            )

            isPaying = false
            onFinish()
        } catch {
            let msg = friendlyPayError(error)
            proximity.sendResponse(
                VendanoPaymentResponse(
                    requestId: request.id,
                    status: .failed,
                    txHash: nil,
                    errorMessage: msg
                )
            )
            feeError = msg

            isPaying = false
        }
    }
    
    private func friendlyPayError(_ error: Error) -> String {
        let raw = error.localizedDescription
        let lower = raw.lowercased()

        // Cardano min-ADA / FeeTooSmallUTxO / token-min-ADA class errors
        if lower.contains("feetoosmallutxo")
            || (lower.contains("fee") && lower.contains("small"))
            || lower.contains("min ada")
            || lower.contains("minimum ada")
            || lower.contains("minutxo")
        {
            return L10n.SendView.cardanoRejectedMinAdaWithTokens
        }

        // Insufficient funds (common across libs/backends)
        if lower.contains("insufficient")
            || lower.contains("utxo balance insufficient")
            || lower.contains("not enough ada")
        {
            return L10n.SendView.notEnoughAdaForTransaction
        }

        // Network-ish failures (no perfect existing "send" string exists)
        // network || offline || timed out || timeout || could not connect || internet

        // Fallback (keep raw so it's at least actionable for debugging)
        return raw.isEmpty ? L10n.Common.unknownError : raw
    }


}

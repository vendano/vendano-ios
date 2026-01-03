//  TapToPayPayerView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 1/2/26.
//

import SwiftUI

struct TapToPayPayerView: View {
    @EnvironmentObject var theme: VendanoTheme
    @Environment(\.dismiss) private var dismiss

    @StateObject private var proximity = ProximityPaymentService.shared

    @State private var showConfirm = false

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            SheetChrome(onClose: { proximity.stop(); dismiss() }) {
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        Text(L10n.StoreView.tapToPayTitle)
                            .vendanoFont(.headline, size: 24, weight: .bold)
                            .foregroundColor(theme.color(named: "TextReversed"))

                        Text(L10n.StoreView.tapToPaySubtitle)
                            .vendanoFont(.body, size: 14)
                            .foregroundColor(theme.color(named: "TextReversed").opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        if proximity.connectedPeerNames.isEmpty {
                            Text(L10n.StoreView.searchingForMerchant)
                                .vendanoFont(.body, size: 16, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextReversed"))
                        } else {
                            Text(L10n.StoreView.connectedTo(proximity.connectedPeerNames.joined(separator: ", ")))
                                .vendanoFont(.body, size: 16, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextReversed"))
                        }

                        if let err = proximity.lastErrorMessage {
                            Text(err)
                                .vendanoFont(.caption, size: 13)
                                .foregroundColor(theme.color(named: "TextReversed").opacity(0.75))
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
        }
        .onAppear {
            proximity.startPayer()
        }
        .onChange(of: proximity.receivedRequest) { _, newValue in
            showConfirm = (newValue != nil)
        }
        .sheet(isPresented: $showConfirm, onDismiss: {
            proximity.receivedRequest = nil
        }) {
            if let req = proximity.receivedRequest {
                PaymentConfirmView(request: req)
                    .environmentObject(theme)
            }
        }
        .onDisappear {
            proximity.stop()
        }
    }
}

private struct PaymentConfirmView: View {
    @EnvironmentObject var theme: VendanoTheme
    @Environment(\.dismiss) private var dismiss

    @StateObject private var wallet = WalletService.shared
    @StateObject private var proximity = ProximityPaymentService.shared

    let request: VendanoPaymentRequest

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

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Spacer()
                    Button {
                        proximity.sendResponse(
                            VendanoPaymentResponse(
                                requestId: request.id,
                                status: .declined,
                                txHash: nil,
                                errorMessage: nil
                            )
                        )
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.color(named: "TextReversed").opacity(0.7))
                    }
                }
                .padding(.horizontal)

                VStack(spacing: 6) {
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
                            Text("\(payerTotalAda.formatted(.number.precision(.fractionLength(3 ... 6)))) ADA")
                                .vendanoFont(.body, size: 16, weight: .semibold)
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
                        Task { await payNow() }
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
                        dismiss()
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
            dismiss()
        } catch {
            proximity.sendResponse(
                VendanoPaymentResponse(
                    requestId: request.id,
                    status: .failed,
                    txHash: nil,
                    errorMessage: error.localizedDescription
                )
            )
            isPaying = false
        }
    }
}

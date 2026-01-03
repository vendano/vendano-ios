//  TapToCollectMerchantView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 1/2/26.
//

import SwiftUI

struct TapToCollectMerchantView: View {
    @EnvironmentObject var theme: VendanoTheme
    @Environment(\.dismiss) private var dismiss

    @StateObject private var state = AppState.shared
    @StateObject private var wallet = WalletService.shared
    @StateObject private var proximity = ProximityPaymentService.shared

    let request: VendanoPaymentRequest

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            SheetChrome(onClose: { proximity.stop(); dismiss() }) {
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        Text(L10n.StoreView.readyToCollectTitle)
                            .vendanoFont(.headline, size: 24, weight: .bold)
                            .foregroundColor(theme.color(named: "TextReversed"))

                        Text(L10n.StoreView.readyToCollectSubtitle)
                            .vendanoFont(.body, size: 14)
                            .foregroundColor(theme.color(named: "TextReversed").opacity(0.75))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 4)

                    VStack(spacing: 10) {
                        Text("\(request.baseAda.formatted(.number.precision(.fractionLength(3 ... 6)))) ADA")
                            .vendanoFont(.title, size: 42, weight: .bold)
                            .foregroundColor(theme.color(named: "TextReversed"))

                        if let rate = wallet.adaFiatRate, rate > 0 {
                            let fiat = request.baseAda * rate
                            Text(L10n.StoreView.approxFiat(wallet.fiatCurrency.rawValue, fiat))
                                .vendanoFont(.body, size: 14)
                                .foregroundColor(theme.color(named: "TextReversed").opacity(0.75))
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(theme.color(named: "CellBackground").opacity(0.22))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 10) {
                        if proximity.connectedPeerNames.isEmpty {
                            Text(L10n.StoreView.waitingForCustomer)
                                .vendanoFont(.body, size: 16, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextReversed"))
                        } else {
                            Text(L10n.StoreView.connectedTo(proximity.connectedPeerNames.joined(separator: ", ")))
                                .vendanoFont(.body, size: 16, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextReversed"))
                        }

                        if let resp = proximity.lastResponse, resp.requestId == request.id {
                            MerchantResponseBanner(response: resp)
                                .environmentObject(theme)
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
            proximity.startMerchant(request: request)
        }
        .onDisappear {
            proximity.stop()
        }
    }
}

private struct MerchantResponseBanner: View {
    @EnvironmentObject var theme: VendanoTheme
    let response: VendanoPaymentResponse

    var body: some View {
        let text: String = {
            switch response.status {
            case .paid:
                return L10n.StoreView.paymentComplete(response.txHash ?? "")
            case .accepted:
                return L10n.StoreView.paymentAccepted
            case .declined:
                return L10n.StoreView.paymentDeclined
            case .failed:
                return L10n.StoreView.paymentFailed(response.errorMessage ?? "")
            case .expired:
                return L10n.StoreView.paymentExpired
            case .cancelled:
                return L10n.StoreView.paymentCancelled
            }
        }()

        return Text(text)
            .vendanoFont(.body, size: 14, weight: .semibold)
            .foregroundColor(theme.color(named: "TextReversed"))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.color(named: "Accent").opacity(0.35))
            .cornerRadius(12)
    }
}

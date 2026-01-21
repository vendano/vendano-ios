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

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            SheetChrome(onClose: {
                proximity.stop(resetAvailability: false)
                dismiss()
            }) {
                if let req = proximity.receivedRequest {
                    PaymentConfirmView(
                        request: req,
                        onBack: { proximity.receivedRequest = nil },
                        onFinish: {
                            proximity.receivedRequest = nil
                            proximity.stop(resetAvailability: false)
                            dismiss()
                        }
                    )
                    .environmentObject(theme)
                } else {
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
        }
        .onAppear {
            proximity.startPayer()
        }
        .onDisappear {
            proximity.stop(resetAvailability: false)
        }
    }
}

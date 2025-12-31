//
//  OfflineBanner.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/21/25.
//

import SwiftUI

struct OfflineBanner: View {
    @EnvironmentObject var theme: VendanoTheme
    @State private var pulse = false

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(VendanoTheme.shared.isHosky() ? "vendoggo-logo" : "vendano-logo")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(theme.color(named: "TextReversed"))
                    .scaledToFit()
                    .frame(width: 120)
                    .padding()
                    .scaleEffect(pulse ? 1.6 : 0.8)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 1)
                                .repeatForever(autoreverses: true)
                        ) {
                            pulse.toggle()
                        }
                    }

                Text(VendanoTheme.shared.isHosky() ? "vendoggo" : "vendano")
                    .vendanoFont(.title, size: 48, weight: .heavy)
                    .foregroundColor(theme.color(named: "TextReversed"))

                Text(L10n.OfflineBanner.noInternetConnectionPleaseCheckYourNetworkAnd)
                    .vendanoFont(.headline, size: 18, weight: .semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.color(named: "TextPrimary").opacity(0.85))

                Spacer().frame(height: 48)

//                Button(L10n.Common.retry) {
//                    // Force a re-check by restarting the monitor:
//                    // (could also attempt a manual reload)
//                    let _ = NetworkMonitor()
//                }
//                .buttonStyle(.plain)
//                .padding()
//                .background(theme.color(named: "TextReversed"))
//                .clipShape(Capsule())
//                .shadow(color: theme.color(named: "Accent").opacity(0.4),
//                        radius: 8, x: 0, y: 4)
//                .overlay(
//                    Capsule().stroke(theme.color(named: "Accent"), lineWidth: 2)
//                )
            }
            .padding()
        }
    }
}

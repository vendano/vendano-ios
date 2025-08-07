//
//  SplashView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var theme: VendanoTheme
    @StateObject private var state = AppState.shared
    @State private var pulse = false

    var loading: Bool

    var body: some View {
        ZStack {
            DarkGradientView()

            VStack(spacing: 24) {
                
                Image(VendanoTheme.shared.isHosky() ? "vendoggo-logo" : "vendano-logo")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(theme.color(named: "TextReversed"))
                    .scaledToFit()
                    .frame(width: 120)
                    .scaleEffect(pulse ? 1.6 : 0.8)
                    .padding()
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                            pulse.toggle()
                        }
                    }

                Text(VendanoTheme.shared.isHosky() ? "vendoggo" : "vendano")
                    .vendanoFont(.title, size: 48, weight: .heavy)
                    .foregroundColor(theme.color(named: "TextReversed"))

                Text("Easy ADA transfers\nby phone or email.")
                    .vendanoFont(.body, size: 18, weight: .semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.color(named: "TextPrimary").opacity(0.85))
                    .animation(nil, value: pulse)

                Spacer()
                    .frame(height: 48)

                if loading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(theme.color(named: "TextReversed"))
                } else {
                    Button("Get started") {
                        state.onboardingStep = .faq
                    }
                    .buttonStyle(.plain)
                    .padding()
                    .background(theme.color(named: "TextReversed"))
                    .clipShape(Capsule())
                    .shadow(color: theme.color(named: "Accent").opacity(0.4), radius: 8, x: 0, y: 4)
                    .overlay(
                        Capsule()
                            .stroke(theme.color(named: "Accent"), lineWidth: 2)
                    )
                }
            }
            .padding()
        }
    }
}

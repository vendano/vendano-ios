//
//  WalletChoiceView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import SwiftUI

struct WalletChoiceView: View {
    @EnvironmentObject var theme: VendanoTheme
    @StateObject private var state = AppState.shared

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 20) {
                    Text("Let’s begin!")
                        .vendanoFont(.title, size: 24, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))

                    Text("To send or receive ADA, you first need a wallet address.")
                        .vendanoFont(.headline, size: 18, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))
                        .padding([.leading, .trailing], 20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Create a new wallet and we’ll give you a secure recovery phrase.")
                        .vendanoFont(.body, size: 16)
                        .foregroundColor(theme.color(named: "TextReversed"))
                        .padding([.leading, .trailing], 20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        state.onboardingStep = .newSeed
                    } label: {
                        Label("Create new wallet", systemImage: "sparkles")
                            .vendanoFont(.body, size: 16)
                    }
                    .buttonStyle(CapsuleButtonStyle())

                    Text("Import an existing wallet by entering your 12-, 15-, or 24-word recovery phrase.")
                        .vendanoFont(.body, size: 16)
                        .foregroundColor(theme.color(named: "TextReversed"))
                        .padding([.leading, .trailing], 20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        state.onboardingStep = .importSeed
                    } label: {
                        Label("Import seed phrase", systemImage: "arrow.up.doc")
                            .vendanoFont(.body, size: 16)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                Spacer()
            }
            .padding()
        }
    }
}

// #Preview {
//    WalletChoiceView()
// }

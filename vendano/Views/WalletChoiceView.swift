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
                    Text(L10n.WalletChoiceView.letSBegin)
                        .vendanoFont(.title, size: 24, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))

                    Text(L10n.WalletChoiceView.toSendOrReceiveAdaYouFirstNeed)
                        .vendanoFont(.headline, size: 18, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))
                        .padding([.leading, .trailing], 20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(L10n.WalletChoiceView.createANewWalletAndWeLlGive)
                        .vendanoFont(.body, size: 16)
                        .foregroundColor(theme.color(named: "TextReversed"))
                        .padding([.leading, .trailing], 20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        state.onboardingStep = .newSeed
                    } label: {
                        Label(L10n.WalletChoiceView.createNewWallet, systemImage: "wallet.bifold")
                            .vendanoFont(.body, size: 16)
                    }
                    .buttonStyle(CapsuleButtonStyle())

                    Text(L10n.WalletChoiceView.importAnExistingWalletByEnteringYour12)
                        .vendanoFont(.body, size: 16)
                        .foregroundColor(theme.color(named: "TextReversed"))
                        .padding([.leading, .trailing], 20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        state.onboardingStep = .importSeed
                    } label: {
                        Label(L10n.WalletChoiceView.importSeedPhrase, systemImage: "arrow.up.doc")
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

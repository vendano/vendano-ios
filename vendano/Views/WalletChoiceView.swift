//
//  WalletChoiceView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import SwiftUI

struct WalletChoiceView: View {
    @StateObject private var state = AppState.shared

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 20) {
                    Text("Let’s begin!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("TextReversed"))

                    Text("To send or receive ADA, you first need a wallet address.")
                        .foregroundColor(Color("TextReversed"))
                        .padding([.leading, .trailing], 20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Create a new wallet and we’ll give you a secure recovery phrase.")
                        .foregroundColor(Color("TextReversed"))
                        .padding([.leading, .trailing], 20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        state.onboardingStep = .newSeed
                    } label: {
                        Label("Create new wallet", systemImage: "sparkles")
                    }
                    .buttonStyle(CapsuleButtonStyle())

                    Text("Import an existing wallet by entering your 12-, 15-, or 24-word recovery phrase.")
                        .foregroundColor(Color("TextReversed"))
                        .padding([.leading, .trailing], 20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        state.onboardingStep = .importSeed
                    } label: {
                        Label("Import seed phrase", systemImage: "arrow.up.doc")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    WalletChoiceView()
}

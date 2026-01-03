//
//  ImportSeedView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/6/25.
//

import SwiftUI

struct ImportSeedView: View {
    @EnvironmentObject var theme: VendanoTheme
    @StateObject private var state = AppState.shared
    @State private var phraseText = ""
    @State private var showError = false
    @State private var errorMessage = L10n.Common.unknownError

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 24) {
                    Text(L10n.ImportSeedView.walletImport)
                        .vendanoFont(.title, size: 24, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))

                    Text(L10n.ImportSeedView.pasteYour1215Or24WordRecovery)
                        .vendanoFont(.body, size: 16)
                        .foregroundColor(theme.color(named: "TextPrimary"))
                        .multilineTextAlignment(.center)

                    TextEditor(text: $phraseText)
                        .vendanoFont(.body, size: 16)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .frame(height: 120)
                        .padding(4)
                        .background(theme.color(named: "FieldBackground"))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.color(named: "CellBackground"), lineWidth: 1))

                    Button(L10n.ImportSeedView.import) {
                        let words = MnemonicText.tokenize(phraseText)

                        guard [12, 15, 18, 21, 24].contains(words.count) else {
                            errorMessage = L10n.ImportSeedView.invalidWordCount
                            showError = true
                            return
                        }

                        guard let lang = MnemonicDetector.detectLanguage(words: words) else {
                            errorMessage = L10n.ImportSeedView.recoveryPhraseNotValidAnyLanguage
                            showError = true
                            return
                        }

                        state.seedWords = words
                        state.seedLanguage = lang

                        // Save both words + language
                        if let data = try? JSONEncoder().encode(words) {
                            KeychainWrapper.standard.set(data, forKey: "seedWords")
                        }
                        KeychainWrapper.standard.set(lang.rawValue, forKey: "seedLanguage")

                        Task {
                            do {
                                try await WalletService.shared.importWallet(words: words, language: lang)
                                if let addr = WalletService.shared.address {
                                    state.walletAddress = addr
                                    try await FirebaseService.shared.saveAddress(addr)
                                }
                                AnalyticsManager.logEvent("onboard_seed_import")
                                state.onboardingStep = .home
                            } catch {
                                DebugLogger.log("⚠️ Wallet creation failed: \(error)")
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(phraseText.isEmpty)

                    Button(L10n.Common.back) {
                        state.onboardingStep = .walletChoice
                    }
                    .foregroundColor(theme.color(named: "Accent"))
                }
                .padding()

                Spacer()
            }
            .alert(L10n.ImportSeedView.invalidRecoveryPhrase, isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
                    .vendanoFont(.body, size: 16)
                    .foregroundColor(theme.color(named: "TextSecondary"))
            }
        }
    }
}

#Preview {
    ImportSeedView()
        .environmentObject(VendanoTheme.shared)
}

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
    @State private var errorMessage = "Unknown error"

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 24) {
                    Text("Wallet Import")
                        .vendanoFont(.title, size: 24, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))

                    Text("Paste your 12-, 15-, or 24-word recovery phrase.")
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

                    Button("Import") {
                        let cleaned = phraseText
                            .lowercased()
                            .replacingOccurrences(of: "[^a-z\\s]", with: "", options: .regularExpression)
                        let words = cleaned
                            .split { $0.isWhitespace }
                            .map(String.init)

                        // simple validation
                        guard [12, 15, 24].contains(words.count) else {
                            showError = true
                            return
                        }

                        state.seedWords = words
                        if let data = try? JSONEncoder().encode(words) {
                            KeychainWrapper.standard.set(data, forKey: "seedWords")
                        }

                        Task {
                            do {
                                try await WalletService.shared.importWallet(words: words)
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

                    Button("Back") {
                        state.onboardingStep = .walletChoice
                    }
                    .foregroundColor(theme.color(named: "Accent"))
                }
                .padding()

                Spacer()
            }
            .alert("Invalid recovery phrase", isPresented: $showError) {
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

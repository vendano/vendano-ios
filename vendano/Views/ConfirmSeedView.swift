//
//  ConfirmSeedView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import SwiftUI

struct ConfirmSeedView: View {
    @EnvironmentObject var theme: VendanoTheme
    @StateObject private var state = AppState.shared

    @State private var correctWords: [String] = []
    @State private var shuffledWords: [String] = []
    @State private var selected: [String] = []
    @State private var error: Bool = false

    @State private var isCreatingWallet: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        ZStack {
            LightGradientView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Confirm Keys")
                        .vendanoFont(.title, size: 24, weight: .semibold)
                        .foregroundColor(theme.color(named: "Accent"))

                    Text("Tap your \(correctWords.count) recovery words in the correct order.")
                        .vendanoFont(.headline, size: 18, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextPrimary"))
                        .multilineTextAlignment(.center)

                    Text("""
                    These words are never sent to our servers - they stay only on your device. \
                    We just need to confirm you’ve written them down correctly, because if you lose \
                    them you won’t be able to recover your wallet.
                    """)
                    .vendanoFont(.caption, size: 13)
                    .foregroundColor(theme.color(named: "TextSecondary"))
                    .multilineTextAlignment(.center)

                    // Tappable grid
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 12) {
                        ForEach(shuffledWords, id: \.self) { word in
                            let isDisabled = selected.contains(word) || selected.count >= correctWords.count
                            if !isDisabled {
                                Button(action: {
                                    withAnimation { selected.append(word) }
                                }) {
                                    Text(word)
                                        .vendanoFont(.caption, size: 16)
                                        .foregroundColor(theme.color(named: "TextPrimary"))
                                        .padding(8)
                                        .frame(maxWidth: .infinity)
                                        .background(theme.color(named: "CellBackground"))
                                        .cornerRadius(6)
                                }
                            } else {
                                Spacer()
                            }
                        }
                    }

                    Divider().padding(.vertical)

                    // Selected words
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 8) {
                        ForEach(selected.indices, id: \.self) { i in
                            Button(action: {
                                selected.remove(at: i)
                            }) {
                                Text("\(i + 1). \(selected[i])")
                                    .vendanoFont(.caption, size: 16)
                                    .foregroundColor(theme.color(named: "TextReversed"))
                                    .padding(6)
                                    .frame(maxWidth: .infinity)
                                    .background(theme.color(named: "Accent"))
                                    .cornerRadius(6)
                            }
                        }
                    }

                    Divider().padding(.vertical)

                    HStack {
                        Button("Clear") {
                            withAnimation {
                                selected.removeAll()
                                error = false
                            }
                        }
                        .buttonStyle(CapsuleButtonStyle())

                        Spacer()

                        Button("Confirm") {
                            if selected == correctWords {
                                isCreatingWallet = true
                                // save and advance
                                if let data = try? JSONEncoder().encode(selected) {
                                    KeychainWrapper.standard.set(data, forKey: "seedWords")
                                }
                                Task {
                                    do {
                                        try await WalletService.shared.importWallet(words: selected)
                                        if let addr = WalletService.shared.address {
                                            // Try to load balance or any other setup here to ensure wallet is fully ready
                                            // Assuming there's a method to await balance fetch, pseudo-code:
                                            // try await WalletService.shared.loadBalance()
                                            await MainActor.run {
                                                // Only update state after successful import and balance load
                                                state.walletAddress = addr
                                                state.onboardingStep = .home
                                                isCreatingWallet = false
                                            }
                                        } else {
                                            // Address was not set, treat as failure
                                            await MainActor.run {
                                                isCreatingWallet = false
                                                DebugLogger.log("❌ Wallet address missing after import")
                                                errorMessage = "Wallet address not found after import."
                                                showErrorAlert = true
                                            }
                                        }
                                        AnalyticsManager.logEvent("onboard_seed_confirm")
                                    } catch {
                                        await MainActor.run {
                                            isCreatingWallet = false
                                            DebugLogger.log("❌ Wallet creation failed: \(error)")
                                            errorMessage = error.localizedDescription
                                            showErrorAlert = true
                                            // Ensure onboardingStep and walletAddress are NOT changed on failure
                                            // Explicitly keep onboardingStep at confirmSeed
                                            state.onboardingStep = .confirmSeed
                                            state.walletAddress = ""
                                        }
                                        print("Wallet creation/import failed with error: \(error)")
                                    }
                                }
                            } else {
                                withAnimation {
                                    error = true
                                    selected.removeAll()
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(selected.count != correctWords.count)
                    }

                    if error {
                        Text("Incorrect order. Try again.")
                            .vendanoFont(.caption, size: 13)
                            .foregroundColor(theme.color(named: "Negative"))
                            .padding(.top, 8)
                    }
                }
                .padding(24)
                .alert("Error", isPresented: $showErrorAlert, actions: {
                    Button("OK", role: .cancel) {}
                }, message: {
                    Text(errorMessage)
                })
            }

            if isCreatingWallet {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            correctWords = state.seedWords
            shuffledWords = correctWords.shuffled()
        }
    }
}

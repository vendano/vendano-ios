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
    @State private var shuffledIndices: [Int] = []   // indexes into correctWords
    @State private var selectedIndices: [Int] = []   // picked indexes, in order
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
                        ForEach(shuffledIndices, id: \.self) { idx in
                            let word = correctWords[idx]
                            let isPicked = selectedIndices.contains(idx)
                            let isDisabled = isPicked || selectedIndices.count >= correctWords.count
                            Button(action: {
                                guard !isDisabled else { return }
                                withAnimation { selectedIndices.append(idx) }
                            }) {
                                Text(word)
                                    .vendanoFont(.caption, size: 16)
                                    .foregroundColor(isPicked
                                                     ? theme.color(named: "TextReversed")
                                                     : theme.color(named: "TextPrimary"))
                                    .padding(8)
                                    .frame(maxWidth: .infinity)
                                    .background(isPicked
                                                ? theme.color(named: "Accent")
                                                : theme.color(named: "CellBackground"))
                                    .cornerRadius(6)
                            }
                            .disabled(isDisabled)
                        }
                    }

                    Divider().padding(.vertical)

                    // Selected words
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 8) {
                        ForEach(selectedIndices.indices, id: \.self) { i in
                            Button(action: {
                                selectedIndices.remove(at: i)
                            }) {
                                Text("\(i + 1). \(correctWords[selectedIndices[i]])")
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
                                selectedIndices.removeAll()
                                error = false
                            }
                        }
                        .buttonStyle(CapsuleButtonStyle())

                        Spacer()

                        Button("Confirm") {
                            let picked = selectedIndices.map { correctWords[$0] }
                            if picked == correctWords {
                                isCreatingWallet = true
                                // save and advance
                                if let data = try? JSONEncoder().encode(picked) {
                                    KeychainWrapper.standard.set(data, forKey: "seedWords")
                                }
                                Task {
                                    // async context already
                                    do {
                                        try await WalletService.shared.importWallet(words: picked)
                                        if let addr = WalletService.shared.address {
                                            // 1) Write to Firestore OFF the main actor
                                            try? await FirebaseService.shared.saveAddress(addr)

                                            // 2) Then update UI ON the main actor
                                            await MainActor.run {
                                                state.walletAddress = addr
                                                state.onboardingStep = .home
                                                isCreatingWallet = false
                                            }
                                            AnalyticsManager.logEvent("onboard_seed_confirm")
                                        } else {
                                            await MainActor.run {
                                                isCreatingWallet = false
                                                DebugLogger.log("❌ Wallet address missing after import")
                                                errorMessage = "Wallet address not found after import."
                                                showErrorAlert = true
                                            }
                                        }
                                    } catch {
                                        await MainActor.run {
                                            isCreatingWallet = false
                                            DebugLogger.log("❌ Wallet creation failed: \(error)")
                                            errorMessage = error.localizedDescription
                                            showErrorAlert = true
                                            state.onboardingStep = .confirmSeed
                                            state.walletAddress = ""
                                        }
                                    }

                                }
                            } else {
                                withAnimation {
                                    error = true
                                    selectedIndices.removeAll()
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(selectedIndices.count != correctWords.count)
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
            shuffledIndices = Array(correctWords.indices).shuffled()
            selectedIndices.removeAll()
            error = false
        }
    }
}

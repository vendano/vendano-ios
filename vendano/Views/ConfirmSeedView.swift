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

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Confirm Keys")
                        .vendanoFont(.title, size: 24, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))

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
                                    .foregroundColor(theme.color(named: "TextPrimary"))
                                    .padding(6)
                                    .frame(maxWidth: .infinity)
                                    .background(theme.color(named: "Accent").opacity(0.15))
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
                                // save and advance
                                if let data = try? JSONEncoder().encode(selected) {
                                    KeychainWrapper.standard.set(data, forKey: "seedWords")
                                }
                                Task {
                                    do {
                                        try await WalletService.shared.createWallet(from: selected)
                                        if let addr = WalletService.shared.address {
                                            state.walletAddress = addr
                                            try await FirebaseService.shared.saveAddress(addr)
                                        }
                                        state.onboardingStep = .home
                                    } catch {
                                        DebugLogger.log("❌ Wallet creation failed: \(error)")
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
            }
        }
        .onAppear {
            correctWords = state.seedWords
            shuffledWords = correctWords.shuffled()
        }
    }
}

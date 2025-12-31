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
                    Text(L10n.ConfirmSeedView.confirmKeys)
                        .vendanoFont(.title, size: 24, weight: .semibold)
                        .foregroundColor(theme.color(named: "Accent"))

                    Text(L10n.ConfirmSeedView.tapRecoveryWordsInstruction(correctWords.count))
                        .vendanoFont(.headline, size: 18, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextPrimary"))
                        .multilineTextAlignment(.center)

                    Text(L10n.ConfirmSeedView.theseWordsAreNeverSentToOurServers)
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
                                    .foregroundColor(theme.color(named: "TextPrimary"))
                                    .padding(6)
                                    .frame(maxWidth: .infinity)
                                    .background(theme.color(named: "CellBackground"))
                                    .cornerRadius(6)
                            }
                        }
                    }

                    Divider().padding(.vertical)

                    HStack {
                        Button(L10n.ConfirmSeedView.clear) {
                            withAnimation {
                                selectedIndices.removeAll()
                                error = false
                            }
                        }
                        .buttonStyle(CapsuleButtonStyle())

                        Spacer()

                        Button(L10n.Common.confirm) {
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
                                                errorMessage = L10n.ConfirmSeedView.walletAddressNotFound
                                                showErrorAlert = true
                                            }
                                        }
                                    } catch {
                                        await MainActor.run {
                                            isCreatingWallet = false

                                            if let decodingError = error as? DecodingError {
                                                switch decodingError {
                                                case .keyNotFound(let key, let context):
                                                    DebugLogger.log("❌ Wallet creation failed – missing key: \(key.stringValue), path: \(context.codingPath.map(\.stringValue))")
                                                    errorMessage = L10n.ConfirmSeedView.walletImportFailedMissingKey(key.stringValue)
                                                case .valueNotFound(let type, let context):
                                                    DebugLogger.log("❌ Wallet creation failed – missing value for type \(type), path: \(context.codingPath.map(\.stringValue))")
                                                    errorMessage = L10n.ConfirmSeedView.walletImportFailedMissingValue(String(describing: type))
                                                case .dataCorrupted(let context):
                                                    DebugLogger.log("❌ Wallet creation failed – data corrupted: \(context.debugDescription)")
                                                    errorMessage = L10n.ConfirmSeedView.walletImportFailedCorruptedData
                                                case .typeMismatch(let type, let context):
                                                    DebugLogger.log("❌ Wallet creation failed – type mismatch \(type): \(context.debugDescription), path: \(context.codingPath.map(\.stringValue))")
                                                    errorMessage = L10n.ConfirmSeedView.walletImportFailedWrongFormat
                                                @unknown default:
                                                    DebugLogger.log("❌ Wallet creation failed – unknown DecodingError: \(decodingError)")
                                                    errorMessage = L10n.ConfirmSeedView.walletImportFailedUnknownDecodingError
                                                }
                                            } else {
                                                let nsError = error as NSError
                                                DebugLogger.log("❌ Wallet creation failed: \(nsError) (domain: \(nsError.domain), code: \(nsError.code))")
                                                errorMessage = nsError.localizedDescription
                                            }

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
                        Text(L10n.ConfirmSeedView.incorrectOrderTryAgain)
                            .vendanoFont(.caption, size: 13)
                            .foregroundColor(theme.color(named: "Negative"))
                            .padding(.top, 8)
                    }
                }
                .padding(24)
                .alert(L10n.ConfirmSeedView.error, isPresented: $showErrorAlert, actions: {
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

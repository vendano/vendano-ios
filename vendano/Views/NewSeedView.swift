//
//  NewSeedView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import Bip39
import SwiftUI

struct NewSeedView: View {
    @EnvironmentObject var theme: VendanoTheme
    @StateObject private var state = AppState.shared

    @State private var acknowledged = false
    @State private var showShotAlert = false
    @State private var words: [String] = []

    @State private var wordCount = 24
    private let options = [12, 15, 24]

    private var strengthBits: Int {
        switch wordCount {
        case 12: return 128
        case 15: return 160
        default: return 256
        }
    }

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text(L10n.NewSeedView.yourRecoveryPhrase)
                        .vendanoFont(.title, size: 24, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))
                        .padding(.top, 40)

                    Text(L10n.NewSeedView.writeTheseWordsInstruction(wordCount))
                        .vendanoFont(.body, size: 16)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(theme.color(named: "TextPrimary"))
                        .padding(.horizontal, 24)

                    Picker(L10n.NewSeedView.words, selection: $wordCount) {
                        ForEach(options, id: \.self) { n in
                            Text(L10n.NewSeedView.wordCountOption(n))
                                .tag(n)
                                .vendanoFont(.body, size: 16)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .onChange(of: wordCount) { _, _ in regenerate() }

                    Text(wordDescription)
                        .vendanoFont(.caption, size: 13)
                        .foregroundStyle(theme.color(named: "TextPrimary"))
                        .padding(.horizontal, 24)

                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 12) {
                        ForEach(words.indices, id: \.self) { idx in
                            let word = words[idx]
                            let isDup = duplicateWords.contains(word)
                            
                            HStack {
                                Text("\(idx + 1).")
                                    .monospacedDigit()
                                    .vendanoFont(.body, size: 16)

                                Text(word)
                                    .vendanoFont(.body, size: 16)

                                Spacer()
                            }
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .padding(8)
                            .background(isDup ? theme.color(named: "FieldBackground") : theme.color(named: "CellBackground"))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)

                    Toggle(L10n.NewSeedView.iWroteThemDownInASafePlace, isOn: $acknowledged)
                        .tint(theme.color(named: "Positive"))
                        .padding(.horizontal, 24)

                    Button(L10n.Common.next) {
                        state.seedWords = words
                        state.onboardingStep = .confirmSeed
                    }
                    .buttonStyle(CapsuleButtonStyle())
                    .disabled(!acknowledged)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }

            .onReceive(NotificationCenter.default.publisher(
                for: UIApplication.userDidTakeScreenshotNotification)
            ) { _ in showShotAlert = true }
            .alert(L10n.NewSeedView.avoidScreenshots, isPresented: $showShotAlert) {
                Button("Got it", role: .cancel) {}
            } message: {
                Text(L10n.NewSeedView.screenshotsMaySyncToIcloudAndExposeYour)
                .vendanoFont(.body, size: 16)
            }
            .onAppear { regenerate() }
        }
    }
    
    private var duplicateWords: Set<String> {
        var seen = Set<String>()
        var dups = Set<String>()
        for w in words {
            if !seen.insert(w).inserted { dups.insert(w) }
        }
        return dups
    }

    private var wordDescription: String {
        switch wordCount {
        case 12:
            return L10n.NewSeedView.wordDescription12
        case 15:
            return L10n.NewSeedView.wordDescription15
        default:
            return L10n.NewSeedView.wordDescription24
        }
    }

    private func regenerate() {
        acknowledged = false
        do {
            let mnemonic = try Mnemonic(strength: strengthBits)
            let lang = state.seedLanguage
            words = mnemonic.mnemonic(wordlist: lang.wordlist)
        } catch {
            DebugLogger.log("⚠️ Failed to generate mnemonic: \(error)")
            words = []
        }
    }
}

// #Preview {
//    NewSeedView()
// }

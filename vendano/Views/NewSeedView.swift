//
//  NewSeedView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import Bip39
import SwiftUI

struct NewSeedView: View {
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
                    Text("Your recovery phrase")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("TextReversed"))
                        .padding(.top, 40)

                    Text("Write these \(wordCount) words in order. If you lose them, your ADA is gone—nobody can reset them.")
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color("TextPrimary"))
                        .padding(.horizontal, 24)

                    Picker("Words", selection: $wordCount) {
                        ForEach(options, id: \.self) { n in
                            Text("\(n) words").tag(n)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .onChange(of: wordCount) { _, _ in regenerate() }

                    Text(wordDescription)
                        .font(.footnote)
                        .foregroundStyle(Color("TextPrimary"))
                        .padding(.horizontal, 24)

                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 12) {
                        ForEach(words.indices, id: \.self) { idx in
                            HStack {
                                Text("\(idx + 1).").monospacedDigit()
                                Text(words[idx])
                                Spacer()
                            }
                            .font(.callout)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .padding(8)
                            .background(Color("CellBackground"))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)

                    Toggle("I wrote them down in a safe place", isOn: $acknowledged)
                        .tint(Color("Positive"))
                        .padding(.horizontal, 24)

                    Button("Next") {
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
            .alert("Avoid screenshots", isPresented: $showShotAlert) {
                Button("Got it", role: .cancel) {}
            } message: {
                Text("""
                Screenshots may sync to iCloud and expose your recovery words. \
                Write them on paper instead and store them in a safe place.
                """)
            }
            .onAppear { regenerate() }
        }
    }

    private var wordDescription: String {
        switch wordCount {
        case 12:
            return "12 words give you strong, industry-standard security for everyday use."
        case 15:
            return "15 words add an extra layer of safety."
        default:
            return "24 words offer the highest protection—ideal if you want maximum peace of mind."
        }
    }

    private func regenerate() {
        acknowledged = false
        do {
            let mnemonic = try Mnemonic(strength: strengthBits)
            words = mnemonic.mnemonic()
        } catch {
            DebugLogger.log("⚠️ Failed to generate mnemonic: \(error)")
            words = []
        }
    }
}

#Preview {
    NewSeedView()
}

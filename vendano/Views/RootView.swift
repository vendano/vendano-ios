//
//  RootView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct RootView: View {
    @StateObject private var state = AppState.shared
    @StateObject private var network = NetworkMonitor()

    var body: some View {
        ZStack {
            NavigationStack {
                switch state.onboardingStep {
                case .loading: SplashView(loading: true)
                case .splash: SplashView(loading: false)
                case .faq: OnboardingFAQCardView(faqs: FAQs.shared.onboarding, onSkip: nil)
                case .auth: AuthView()
                case .otp: OTPView()
                case .profile: CreateProfileView()
                case .walletChoice: WalletChoiceView()
                case .newSeed: NewSeedView()
                case .importSeed: ImportSeedView()
                case .confirmSeed: ConfirmSeedView()
                case .home: HomeView().ignoresSafeArea(edges: .bottom)
                case .send: SendView { state.onboardingStep = .home }
                case .receive: ReceiveView { state.onboardingStep = .home }
                }
            }
            if !network.isConnected {
                OfflineBanner()
            }
        }
        .task {
            _ = BlurOverlay()

            guard Auth.auth().currentUser != nil else { return }

            state.onboardingStep = .loading
            state.loadImage()

            do {
                let onboardingStep = try await FirebaseService.shared.getUserStatus()
                if onboardingStep == .walletChoice {
                    // check for saved wallet first

                    if let saved = loadSeedWords() {
                        Task {
                            try? await WalletService.shared.createWallet(from: saved)

                            if WalletService.shared.address != nil {
                                state.walletAddress = WalletService.shared.address ?? ""
                                state.onboardingStep = .home
                            } else {
                                state.onboardingStep = onboardingStep
                            }
                        }
                    } else {
                        state.onboardingStep = .walletChoice
                    }
                } else {
                    state.onboardingStep = onboardingStep
                }
            } catch {
                DebugLogger.log("⚠️ Failed to fetch user status: \(error)")
                state.onboardingStep = .auth
            }
        }
    }

    func loadSeedWords() -> [String]? {
        guard let data = KeychainWrapper.standard.data(forKey: "seedWords") else {
            return nil
        }
        return try? JSONDecoder().decode([String].self, from: data)
    }
}

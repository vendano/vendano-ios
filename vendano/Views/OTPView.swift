//
//  OTPView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import FirebaseAuth
import SwiftUI

struct OTPView: View {
    @EnvironmentObject var theme: VendanoTheme
    @StateObject private var state = AppState.shared
    @State private var pastedLink = "" // only for Simulator

    #if targetEnvironment(simulator)
        let isSimulator = true
    #else
        let isSimulator = false
    #endif

    @State private var code = ""
    @State private var errorMessage: String?
    @FocusState private var keyboardFocused: Bool

    private let maxDigits = 6
    private var isEmail: Bool { !(state.otpEmail == nil) }

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Text(isEmail ? L10n.OTPView.verifyYourEmail : L10n.OTPView.enterYourCode)
                        .vendanoFont(.title, size: 24, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))

                    if isEmail {
                        Text(L10n.OTPView.tapTheSignInLinkWeSentTo)
                            .vendanoFont(.body, size: 16)
                    } else {
                        Text(L10n.OTPView.weSentA6DigitCodeTo)
                            .vendanoFont(.body, size: 16)
                    }
                    Text(isEmail ? (state.otpEmail ?? "") : (state.otpPhone ?? ""))
                        .vendanoFont(.headline, size: 18, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextPrimary"))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                if isEmail {
                    if isSimulator {
                        VStack(spacing: 16) {
                            Text(L10n.OTPView.simulatorCanTOpenUniversalLinksPasteIt)
                                .vendanoFont(.caption, size: 13)
                                .foregroundColor(theme.color(named: "TextSecondary"))

                            TextField(L10n.OTPView.pasteSignInLink, text: $pastedLink)
                                .vendanoFont(.body, size: 18)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .padding(.horizontal, 24)

                            Button(L10n.Common.confirm) {
                                Task {
                                    do {
                                        try await FirebaseService.shared.confirmEmailLink(link: pastedLink, email: state.otpEmail ?? "")
                                        state.onboardingStep = .profile
                                    } catch {
                                        errorMessage = error.localizedDescription
                                    }
                                }
                            }
                            .buttonStyle(CapsuleButtonStyle())
                            .disabled(pastedLink.isEmpty)
                            .padding(.horizontal, 24)
                        }
                    } else {
                        ProgressView(L10n.OTPView.waitingForConfirmation)
                            .progressViewStyle(.circular)
                            .foregroundColor(theme.color(named: "TextReversed"))
                            .padding(.top, 16)
                    }

                } else {
                    VStack(spacing: 16) {
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .vendanoFont(.body, size: 16)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        // hidden field captures paste & keyboard
                        TextField("", text: $code)
                            .vendanoFont(.body, size: 18)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .foregroundColor(.clear)
                            .accentColor(.clear)
                            .focused($keyboardFocused)
                            .onAppear { keyboardFocused = true }
                            .onChange(of: code) { _, newValue in
                                let digits = newValue.filter(\.isWholeNumber)
                                code = String(digits.prefix(maxDigits))
                            }

                        // code boxes
                        HStack(spacing: 12) {
                            ForEach(0 ..< maxDigits, id: \.self) { idx in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(idx == code.count ? theme.color(named: "FieldBackground") : theme.color(named: "TextPrimary"),
                                                lineWidth: 2)
                                        .frame(width: 44, height: 54)

                                    Text(code.digit(at: idx))
                                        .vendanoFont(.headline, size: 18, weight: .semibold)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { keyboardFocused = true }

                        // verify button
                        Button(L10n.OTPView.verify) {
                            FirebaseService.shared.confirmPhoneOTP(code: code) { err in
                                if let err = err {
                                    errorMessage = err
                                } else {
                                    errorMessage = nil
                                    state.onboardingStep = .profile
                                }
                            }
                        }
                        .buttonStyle(CapsuleButtonStyle())
                        .disabled(code.count < maxDigits)
                        .padding(.horizontal, 24)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 40)
        }
        .onAppear {
            // if already signed in via email link on device
            if state.environment == .appstorereview {
                state.onboardingStep = .profile
            }
            if isEmail, Auth.auth().currentUser != nil {
                state.onboardingStep = .profile
            }
        }
    }
}

// #Preview {
//    OTPView()
// }

//
//  OTPView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import FirebaseAuth
import SwiftUI

struct OTPView: View {
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
                    Text(isEmail ? "Verify your email" : "Enter your code")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("TextReversed"))

                    if isEmail {
                        Text("Tap the sign-in link we sent to:")
                    } else {
                        Text("We sent a 6-digit code to:")
                    }
                    Text(isEmail ? (state.otpEmail ?? "") : (state.otpPhone ?? ""))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color("TextPrimary"))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                if isEmail {
                    if isSimulator {
                        VStack(spacing: 16) {
                            Text("Simulator can’t open universal links. Paste it here:")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            TextField("Paste sign-in link", text: $pastedLink)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .padding(.horizontal, 24)

                            Button("Confirm") {
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
                        ProgressView("Waiting for confirmation…")
                            .progressViewStyle(.circular)
                            .foregroundColor(Color("TextReversed"))
                            .padding(.top, 16)
                    }

                } else {
                    VStack(spacing: 16) {
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }

                        // hidden field captures paste & keyboard
                        TextField("", text: $code)
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
                                        .stroke(idx == code.count ? Color("FieldBackground") : Color("TextPrimary"),
                                                lineWidth: 2)
                                        .frame(width: 44, height: 54)

                                    Text(code.digit(at: idx))
                                        .font(.title2.weight(.semibold))
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { keyboardFocused = true }

                        // verify button
                        Button("Verify") {
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
            if isEmail, Auth.auth().currentUser != nil {
                state.onboardingStep = .profile
            }
        }
    }
}

// #Preview {
//    OTPView()
// }

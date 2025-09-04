//
//  AuthView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import FirebaseAuth
import SwiftUI

struct AuthView: View {
    @EnvironmentObject var theme: VendanoTheme
    @StateObject private var state = AppState.shared

    @State private var email = ""
    @State private var dialCode = "+1"
    @State private var localNumber = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    @FocusState private var emailFocus: Bool
    @FocusState private var phoneFocus: Bool

    @State private var useEmail = true

    private var emailIsValid: Bool {
        email.contains("@") && email.contains(".")
    }

    private var phoneIsValid: Bool {
        let digits = localNumber.filter(\.isNumber)
        return digits.count >= 6 && digits.count <= 15 && dialCode.starts(with: "+")
    }

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Login / Register")
                    .vendanoFont(.title, size: 24, weight: .semibold)
                    .foregroundColor(theme.color(named: "TextReversed"))

                Text("Enter your email or phone number and we’ll text / email a one-time code—no passwords needed.")
                    .vendanoFont(.headline, size: 18)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.color(named: "TextPrimary"))

                Picker("", selection: $useEmail) {
                    Text("Email")
                        .tag(true)
                        .vendanoFont(.body, size: 16)
                    Text("Phone")
                        .tag(false)
                        .vendanoFont(.body, size: 16)
                }
                .pickerStyle(.segmented)
                .tint(theme.color(named: "Accent"))
                .onChange(of: useEmail) { _, _ in errorMessage = nil }

                if let error = errorMessage {
                    Text(error)
                        .vendanoFont(.caption, size: 13)
                        .multilineTextAlignment(.center)
                        .foregroundColor(theme.color(named: "Negative"))
                        .padding(.top, 4)
                }

                if useEmail {
                    TextField(
                        "",
                        text: $email,
                        prompt: Text("you\u{200B}@example.com")
                            .foregroundColor(theme.color(named: "Accent"))
                    )
                    .vendanoFont(.body, size: 18)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(nil)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(theme.color(named: "FieldBackground"))
                    .cornerRadius(8)
                    .foregroundColor(theme.color(named: "TextPrimary"))
                    .focused($emailFocus)
                    .onAppear { emailFocus = true }

                } else {
                    HStack(spacing: 12) {
                        TextField("+1", text: $dialCode)
                            .vendanoFont(.body, size: 18)
                            .keyboardType(.phonePad)
                            .padding()
                            .frame(width: 70)
                            .background(theme.color(named: "FieldBackground"))
                            .cornerRadius(8)
                            .foregroundColor(theme.color(named: "TextPrimary"))

                        AuthPhoneField(localNumber: $localNumber)
                            .vendanoFont(.body, size: 18)
                            .padding()
                            .background(theme.color(named: "FieldBackground"))
                            .cornerRadius(8)
                            .focused($phoneFocus)
                            .onAppear { phoneFocus = true }
                    }
                }

                Button {
                    state.onboardingStep = .otp
                    sendCode()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(theme.color(named: "TextReversed"))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Send code")
                            .vendanoFont(.body, size: 16)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(CapsuleButtonStyle())
                .disabled(isLoading || (useEmail ? !emailIsValid : !phoneIsValid))
                .opacity(isLoading ? 0.7 : 1)

                Text("(If you’re new, we’ll create an account automatically.)")
                    .vendanoFont(.caption, size: 13)
                    .multilineTextAlignment(.center)
                    .foregroundColor(theme.color(named: "TextSecondary"))
                    .padding(.top, 4)
            }
            .padding()
        }
        .animation(.easeInOut, value: useEmail)
    }

    private func sendCode() {
        isLoading = true
        errorMessage = nil
        
        let phone = "\(dialCode) \(localNumber)".trimmingCharacters(in: .whitespaces)
        
        let env = state.resolveEnvironment(for: useEmail ? email : phone)
        state.setEnvironment(env)

        if useEmail {
            state.otpEmail = email
            FirebaseService.shared.sendEmailLink(to: email) { err in
                isLoading = false
                if let err = err {
                    errorMessage = "Error sending email link: \(err.localizedDescription)"
                } else {
                    state.onboardingStep = .otp
                }
            }
        } else {
            state.otpPhone = phone
            FirebaseService.shared.sendPhoneOTP(e164: phone) {
                isLoading = false
                state.onboardingStep = .otp
            }
        }
    }
}

// #Preview {
//    AuthView()
// }

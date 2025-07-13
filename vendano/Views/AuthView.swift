//
//  AuthView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import FirebaseAuth
import SwiftUI

struct AuthView: View {
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
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("TextReversed"))

                Text("Enter your email or phone number and we’ll text / email a one-time code—no passwords needed.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("TextPrimary"))

                Picker("", selection: $useEmail) {
                    Text("Email").tag(true)
                    Text("Phone").tag(false)
                }
                .pickerStyle(.segmented)
                .tint(Color("Accent"))
                .onChange(of: useEmail) { _, _ in errorMessage = nil }

                if let error = errorMessage {
                    Text(error)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color("Negative"))
                        .padding(.top, 4)
                }

                if useEmail {
                    TextField(
                        "",
                        text: $email,
                        prompt: Text("you@example.com")
                            .foregroundColor(Color("Accent"))
                    )
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color("FieldBackground"))
                    .cornerRadius(8)
                    .foregroundColor(Color("TextPrimary"))
                    .focused($emailFocus)
                    .onAppear { emailFocus = true }

                } else {
                    HStack(spacing: 12) {
                        TextField("+1", text: $dialCode)
                            .keyboardType(.phonePad)
                            .padding()
                            .frame(width: 70)
                            .background(Color("FieldBackground"))
                            .cornerRadius(8)
                            .foregroundColor(Color("TextPrimary"))

                        AuthPhoneField(localNumber: $localNumber)
                            .padding()
                            .background(Color("FieldBackground"))
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
                            .tint(Color("TextReversed"))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Send code")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(CapsuleButtonStyle())
                .disabled(isLoading || (useEmail ? !emailIsValid : !phoneIsValid))
                .opacity(isLoading ? 0.7 : 1)

                Text("(If you’re new, we’ll create an account automatically.)")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("TextSecondary"))
                    .padding(.top, 4)
            }
            .padding()
        }
        .animation(.easeInOut, value: useEmail)
    }

    private func sendCode() {
        isLoading = true
        errorMessage = nil

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
            let phone = "\(dialCode) \(localNumber)".trimmingCharacters(in: .whitespaces)
            state.otpPhone = phone
            FirebaseService.shared.sendPhoneOTP(e164: phone) {
                isLoading = false
                state.onboardingStep = .otp
            }
        }
    }
}

#Preview {
    AuthView()
}

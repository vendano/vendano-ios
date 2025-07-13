//
//  NewContactAuthView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/12/25.
//

import FirebaseAuth
import SwiftUI

enum ContactMethod: String, Identifiable {
    case email, phone
    var id: String { rawValue }
}

struct NewContactAuthView: View {
    @Environment(\.dismiss) private var dismiss

    let method: ContactMethod
    var onComplete: (() -> Void)?

    // MARK: Entry State

    @State private var email = ""
    @State private var dialCode = "+1"
    @State private var localNumber = ""
    @State private var errorMessage: String?
    @State private var sent = false

    @FocusState private var entryFieldIsFocused: Bool
    @FocusState private var verifyFieldIsFocused: Bool

    // MARK: Verify State

    @State private var code = ""
    @FocusState private var keyboardFocused: Bool
    private let maxDigits = 6

    private var emailIsValid: Bool {
        email.contains("@") && email.contains(".")
    }

    private var phoneIsValid: Bool {
        let digits = localNumber.filter(\.isWholeNumber)
        return digits.count >= 6 && digits.count <= 15 && dialCode.starts(with: "+")
    }

    #if targetEnvironment(simulator)
        private let isSimulator = true
    #else
        private let isSimulator = false
    #endif

    var body: some View {
        ZStack {
            LightGradientView()
                .ignoresSafeArea()

            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text(sent
                        ? (method == .email ? "Verify your email" : "Enter your code")
                        : (method == .email ? "Add Email" : "Add Phone"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("TextPrimary"))

                    if !sent {
                        Text(method == .email
                            ? "Enter the email you’d like to add."
                            : "Enter the phone number you’d like to add.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color("TextPrimary"))
                    } else {
                        Text(method == .email
                            ? "Tap the link we sent to:"
                            : "We sent a 6-digit code to:")
                            .foregroundColor(Color("TextPrimary"))
                        Text(method == .email ? email : "\(dialCode) \(localNumber)")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(Color("TextPrimary"))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)

                if !sent {
                    entryView
                        .onAppear {
                            entryFieldIsFocused = true
                        }
                } else {
                    verifyView
                        .onAppear {
                            verifyFieldIsFocused = true
                        }
                }

                Spacer()
            }
            .padding(.vertical, 20)
        }
        .presentationDetents([.fraction(0.4)])
    }

    // MARK: ENTRY

    private var entryView: some View {
        VStack(spacing: 16) {
            if let err = errorMessage {
                Text(err)
                    .foregroundColor(Color("Negative"))
                    .multilineTextAlignment(.center)
            }

            if method == .email {
                TextField("you@example.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color("FieldBackground"))
                    .cornerRadius(8)
                    .focused($entryFieldIsFocused)
            } else {
                HStack(spacing: 12) {
                    TextField("+1", text: $dialCode)
                        .frame(width: 60)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color("FieldBackground"))
                        .cornerRadius(8)

                    TextField("5551234567", text: $localNumber)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color("FieldBackground"))
                        .cornerRadius(8)
                        .focused($entryFieldIsFocused)
                }
            }

            Button("Send Code") {
                sendCode()
            }
            .buttonStyle(CapsuleButtonStyle())
            .disabled(method == .email ? !emailIsValid : !phoneIsValid)
        }
        .padding(.horizontal, 24)
    }

    // MARK: VERIFY

    private var verifyView: some View {
        VStack(spacing: 16) {
            if method == .email {
                if isSimulator {
                    Text("Simulator can’t open universal links. Paste it here:")
                        .font(.footnote)
                        .foregroundColor(Color("TextSecondary"))

                    TextField("Paste sign-in link", text: $code)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color("FieldBackground"))
                        .cornerRadius(8)
                        .focused($verifyFieldIsFocused)

                    Button("Confirm") {
                        Task {
                            do {
                                try await FirebaseService.shared.confirmEmailLink(link: code, email: email)
                                finish()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .buttonStyle(CapsuleButtonStyle())
                    .disabled(code.isEmpty)
                } else {
                    ProgressView("Waiting for confirmation…")
                        .progressViewStyle(.circular)
                        .tint(Color("TextPrimary"))
                        .onAppear { /* your onOpenURL handler will finish() */ }
                }
            } else {
                if let err = errorMessage {
                    Text(err)
                        .foregroundColor(Color("Negative"))
                        .multilineTextAlignment(.center)
                }

                // hidden capture field
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

                HStack(spacing: 12) {
                    ForEach(0 ..< maxDigits, id: \.self) { idx in
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(idx == code.count
                                    ? Color("Accent")
                                    : Color("FieldBackground"),
                                    lineWidth: 2)
                                .frame(width: 44, height: 54)
                            Text(code.digit(at: idx))
                                .font(.title2.monospacedDigit())
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { keyboardFocused = true }

                Button("Verify") {
                    confirmCode()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(code.count < maxDigits)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: ACTIONS

    private func sendCode() {
        errorMessage = nil
        if method == .email {
            FirebaseService.shared.sendEmailLink(to: email) { err in
                if let e = err { errorMessage = e.localizedDescription } else { sent = true }
            }
        } else {
            let phone = "\(dialCode)\(localNumber)"
            FirebaseService.shared.sendPhoneOTP(e164: phone) {
                sent = true
            }
        }
    }

    private func confirmCode() {
        FirebaseService.shared.confirmPhoneOTP(code: code) { err in
            if let e = err { errorMessage = e } else { finish() }
        }
    }

    private func finish() {
        onComplete?()
        dismiss()
    }
}

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
    @EnvironmentObject var theme: VendanoTheme
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

    private var titleKey: LocalizedStringKey {
        if sent {
            return method == .email
                ? L10n.NewContactAuthView.verifyYourEmail
                : L10n.NewContactAuthView.enterYourCode
        } else {
            return method == .email
                ? L10n.NewContactAuthView.addEmail
                : L10n.NewContactAuthView.addPhone
        }
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
                    Text(titleKey)
                        .vendanoFont(.title, size: 24, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextPrimary"))

                    if !sent {
                        Text(method == .email
                            ? L10n.NewContactAuthView.enterEmailToAdd
                            : L10n.NewContactAuthView.enterPhoneToAdd)
                            .vendanoFont(.body, size: 16)
                            .multilineTextAlignment(.center)
                            .foregroundColor(theme.color(named: "TextPrimary"))
                    } else {
                        Text(method == .email
                            ? L10n.NewContactAuthView.tapLinkWeSentTo
                            : L10n.NewContactAuthView.sentSixDigitCodeTo)
                            .vendanoFont(.body, size: 16)
                            .foregroundColor(theme.color(named: "TextPrimary"))
                        Text(method == .email ? email : "\(dialCode) \(localNumber)")
                            .vendanoFont(.headline, size: 18, weight: .semibold)
                            .foregroundColor(theme.color(named: "TextPrimary"))
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
                    .vendanoFont(.body, size: 16)
                    .foregroundColor(theme.color(named: "Negative"))
                    .multilineTextAlignment(.center)
            }

            if method == .email {
                TextField(L10n.NewContactAuthView.youExampleCom, text: $email)
                    .vendanoFont(.body, size: 18)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(nil)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(theme.color(named: "FieldBackground"))
                    .cornerRadius(8)
                    .focused($entryFieldIsFocused)
            } else {
                HStack(spacing: 12) {
                    TextField(L10n.NewContactAuthView.text1, text: $dialCode)
                        .vendanoFont(.body, size: 18)
                        .frame(width: 60)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(theme.color(named: "FieldBackground"))
                        .cornerRadius(8)

                    TextField(L10n.NewContactAuthView.text5551234567, text: $localNumber)
                        .vendanoFont(.body, size: 18)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(theme.color(named: "FieldBackground"))
                        .cornerRadius(8)
                        .focused($entryFieldIsFocused)
                }
            }

            Button(L10n.NewContactAuthView.sendCode) {
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
                    Text(L10n.NewContactAuthView.simulatorCanTOpenUniversalLinksPasteIt)
                        .vendanoFont(.caption, size: 13)
                        .foregroundColor(theme.color(named: "TextSecondary"))

                    TextField(L10n.NewContactAuthView.pasteSignInLink, text: $code)
                        .vendanoFont(.body, size: 18)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(theme.color(named: "FieldBackground"))
                        .cornerRadius(8)
                        .focused($verifyFieldIsFocused)

                    Button(L10n.Common.confirm) {
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
                    ProgressView(L10n.NewContactAuthView.waitingForConfirmation)
                        .progressViewStyle(.circular)
                        .tint(theme.color(named: "TextPrimary"))
                        .onAppear { /* your onOpenURL handler will finish() */ }
                }
            } else {
                if let err = errorMessage {
                    Text(err)
                        .vendanoFont(.body, size: 16)
                        .foregroundColor(theme.color(named: "Negative"))
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
                                    ? theme.color(named: "Accent")
                                    : theme.color(named: "FieldBackground"),
                                    lineWidth: 2)
                                .frame(width: 44, height: 54)
                            Text(code.digit(at: idx))
                                .vendanoFont(.title, size: 24, weight: .semibold)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { keyboardFocused = true }

                Button(L10n.NewContactAuthView.verify) {
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
            let phone = "\(dialCode) \(localNumber)".trimmingCharacters(in: .whitespaces)
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

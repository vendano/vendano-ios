//
//  SendView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import Cardano
import LocalAuthentication
import MessageUI
import PhoneNumberKit
import SwiftUI

enum SendMethod: String, CaseIterable, Identifiable {
    case email
    case phone
    case address

    var id: String { rawValue }

    var label: LocalizedStringKey {
        switch self {
        case .email: return L10n.SendView.sendMethodEmail
        case .phone: return L10n.SendView.sendMethodPhone
        case .address: return L10n.SendView.sendMethodAddress
        }
    }
}


struct SendView: View {
    @EnvironmentObject var theme: VendanoTheme
    
    @AppStorage("didShowSendAuthPrimer") private var didShowSendAuthPrimer = false
    @State private var showSendAuthPrimer = false

    @State private var showTapToPay = false

    @StateObject private var state = AppState.shared
    @StateObject private var wallet = WalletService.shared
    @StateObject private var kb = KeyboardGuardian()

    let onClose: () -> Void

    @State private var sendMethod: SendMethod = .email

    @State private var email = ""
    @State private var dialCode = "+1"
    @State private var localNumber = ""
    @State private var addressText = ""
    @State private var recipient: Recipient?
    @State private var lookupTask: Task<Void, Never>?
    @State private var showWarning = false
    @State private var feeError: String?

    // MARK: – Alert state

    @State private var isSending = false
    @State private var sendSuccess = false
    @State private var sendError: String?
    @State private var showInviteAlert = false
    @State private var inviteTitle = ""
    @State private var inviteMessage = ""
    @State private var shareInvite: ShareMessage?
    
    @State private var didApplyDraft: Bool = false

    private var recipientOK: Bool {
        switch sendMethod {
        case .email:
            return emailOK
        case .phone:
            return phoneOK
        case .address:
            let trimmed = addressText.trimmingCharacters(in: .whitespacesAndNewlines)
            let hasRawAddress = isValidCardanoAddress(trimmed)
            let hasResolvedRecipient = !(recipient?.address ?? "").isEmpty
            return hasRawAddress || hasResolvedRecipient
        }
    }

    @FocusState private var emailFocus: Bool
    @FocusState private var phoneFocus: Bool
    @FocusState private var addrFocus: Bool

    @State private var adaText = ""

    @State private var netFee: Double = 0
    @State private var feeLoading = false

    private var adaValue: Double? { Double(adaText) }
    private var appFee: Double {
        guard let ada = adaValue else { return 0 }
        return wallet.effectiveAppFee(for: ada)
    }

    //    private let phoneKit = PhoneNumberUtility()
    //    private let phoneFmt = PartialFormatter()

    @State private var includeTip = false
    @State private var tipText = ""

    @State private var showNotificationPrompt = false

    // rudimentary checks
    private var emailOK: Bool {
        email.contains("@") && email.contains(".")
    }

    private var phoneOK: Bool {
        let digits = localNumber.filter(\.isWholeNumber)
        return digits.count >= 6 && digits.count <= 15 && dialCode.hasPrefix("+")
    }

    private func isValidCardanoAddress(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return (try? Address(bech32: trimmed)) != nil
    }

    private var tipValue: Double { Double(tipText) ?? 0 }
    
    private var amountOK: Bool {
        let base = (adaValue ?? 0) + netFee + appFee + tipValue
        let maxSpendable = wallet.spendableAda ?? wallet.adaBalance
        return (adaValue ?? 0) > 0 && base <= maxSpendable
    }

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack {
                // close button
                HStack {
                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.color(named: "TextReversed").opacity(0.7))
                    }
                }
                .padding(.horizontal)

                // form
                Form {

                    Section {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            showTapToPay = true
                        } label: {
                            Label(L10n.StoreView.tapToPay, systemImage: "wave.3.right")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .listRowBackground(theme.color(named: "CellBackground"))

                    Section(header: Text(L10n.SendView.to)
                        .vendanoFont(.headline, size: 18, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))
                    ) {
                        Picker("", selection: $sendMethod) {
                            ForEach(SendMethod.allCases) { method in
                                Text(method.label)
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextPrimary"))
                                    .tag(method)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 4)
                        .background(theme.color(named: "FieldBackground"))
                        .cornerRadius(8)
                        .onChange(of: sendMethod) { _, newMethod in
                            switch newMethod {
                            case .email:
                                emailFocus = true
                            case .phone:
                                phoneFocus = true
                            case .address:
                                addrFocus = true
                            }
                        }

                        switch sendMethod {
                        case .email:
                            TextField(L10n.SendView.youExampleCom, text: $email)
                                .vendanoFont(.body, size: 18)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .textContentType(nil)
                                .padding(12)
                                .background(theme.color(named: "FieldBackground"))
                                .cornerRadius(8)
                                .focused($emailFocus)
                                .onChange(of: email) { _, _ in
                                    if emailOK {
                                        lookupRecipient()
                                    }
                                }
                        case .phone:
                            HStack(spacing: 12) {
                                TextField(L10n.SendView.text1, text: $dialCode)
                                    .vendanoFont(.body, size: 18)
                                    .keyboardType(.phonePad)
                                    .padding(12)
                                    .background(theme.color(named: "FieldBackground"))
                                    .cornerRadius(8)
                                    .frame(width: 80)
                                    .onChange(of: dialCode) { _, _ in
                                        if phoneOK {
                                            lookupRecipient()
                                        }
                                    }
                                TextField(L10n.SendView.text5551234567, text: $localNumber)
                                    .vendanoFont(.body, size: 18)
                                    .keyboardType(.phonePad)
                                    .padding(12)
                                    .background(theme.color(named: "FieldBackground"))
                                    .cornerRadius(8)
                                    .focused($phoneFocus)
                                    .onChange(of: localNumber) { _, _ in
                                        if phoneOK {
                                            lookupRecipient()
                                        }
                                    }
                            }
                        case .address:
                            TextField(L10n.SendView.pasteACardanoAddressOrHandle, text: $addressText)
                                .vendanoFont(.body, size: 18)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .padding(12)
                                .background(theme.color(named: "FieldBackground"))
                                .cornerRadius(8)
                                .focused($addrFocus)
                                .onChange(of: addressText) { _, _ in
                                    lookupRecipient()
                                    if isValidCardanoAddress(addressText), (Double(adaText) ?? 0) > 0 {
                                        recalcFee()
                                    }
                                }

                        }

                        if let rec = recipient {
                            HStack(spacing: 12) {
                                AvatarThumb(
                                    localImage: nil,
                                    url: URL(string: rec.avatarURL ?? ""),
                                    name: rec.name,
                                    size: 36,
                                    tap: {}
                                )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rec.name)
                                        .vendanoFont(.body, size: 16, weight: .semibold)
                                        .foregroundColor(theme.color(named: "TextPrimary"))

                                    Text(rec.address)
                                        .vendanoFont(.caption, size: 13)
                                        .foregroundColor(theme.color(named: "TextSecondary"))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                            .padding()
                        }
                    }
                    .listRowBackground(theme.color(named: "CellBackground"))

                    Section(header: Text(L10n.SendView.amount)
                        .vendanoFont(.headline, size: 18, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))
                    ) {
                        HStack {
                            TextField(L10n.SendView.text00, text: $adaText)
                                .vendanoFont(.body, size: 18)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .padding(12)
                                .background(theme.color(named: "FieldBackground"))
                                .cornerRadius(8)

                            Spacer()

                            if let ada = adaValue,
                               let fiatRate = wallet.adaFiatRate
                            {
                                Text("₳ ≈ \(wallet.fiatCurrency.symbol)\((ada * fiatRate).formatted(.number.precision(.fractionLength(2))))")
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextSecondary"))
                            }

                            Button(L10n.SendView.all) {
                                // Single source of truth: Home + Send both trust adaBalance
                                let available = wallet.adaBalance

                                // Leave headroom for network fee + Vendano fee.
                                // For small wallets this is conservative; for bigger ones it’s still tiny.
                                let headroom = 1.0  // 1 ADA safety margin

                                var maxAmount = max(available - headroom - tipValue, 0)

                                // Avoid negative/tiny dust values
                                if maxAmount < 0.000_001 {
                                    maxAmount = 0
                                }

                                adaText = (maxAmount).formatted(.number.precision(.fractionLength(6)))

                                // Recalculate fee for the new amount
                                recalcFee()
                            }
                            .vendanoFont(.body, size: 16, weight: .semibold)
                            .padding()
                            .background(theme.color(named: "Accent"))
                            .foregroundColor(theme.color(named: "TextReversed"))
                            .clipShape(Capsule())


                        }

                        if let ada = adaValue, ada > 0 {
                            Toggle(L10n.SendView.addATipForTheDeveloper, isOn: $includeTip)
                                .tint(theme.color(named: "Accent"))
                                .foregroundColor(theme.color(named: "TextPrimary"))
                                .padding()
                                .onChange(of: includeTip) { _, newVal in
                                    if !newVal {
                                        tipText = ""
                                    }
                                }

                            if includeTip {
                                HStack {
                                    TextField(L10n.SendView.text000, text: $tipText)
                                        .vendanoFont(.body, size: 18)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .padding(12)
                                        .background(theme.color(named: "FieldBackground"))
                                        .cornerRadius(8)
                                        .onChange(of: tipText) { _, new in
                                            tipText = sanitizeDecimal(new)
                                        }

                                    Spacer()

                                    Text(L10n.SendView.tipAmount)
                                        .vendanoFont(.body, size: 16)
                                        .foregroundColor(theme.color(named: "TextPrimary"))
                                }
                                .padding(.vertical, 4)

                                Text(L10n.SendView.networkFeesCoverBasicBlockchainCostsAnyExtra)
                                    .vendanoFont(.caption, size: 14)
                                    .foregroundColor(theme.color(named: "TextSecondary"))
                                    .padding()
                            }
                        }
                    }
                    .listRowBackground(theme.color(named: "CellBackground"))

                    if let ada = adaValue, ada > 0 {
                        Section(header: Text(L10n.SendView.summary)
                            .vendanoFont(.headline, size: 18, weight: .semibold)
                            .foregroundColor(theme.color(named: "TextReversed"))
                        ) {
                            HStack {
                                Text(L10n.SendView.amount)
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextPrimary"))

                                Spacer()

                                Text("\((ada).formatted(.number.precision(.fractionLength(2)))) ₳")
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextPrimary"))
                            }

                            if tipValue > 0 {
                                HStack {
                                    Text(L10n.SendView.tip)
                                        .vendanoFont(.body, size: 16)
                                        .foregroundColor(theme.color(named: "TextPrimary"))

                                    Spacer()

                                    Text("\((tipValue).formatted(.number.precision(.fractionLength(2)))) ₳")
                                        .vendanoFont(.body, size: 16)
                                        .foregroundColor(theme.color(named: "TextPrimary"))
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(L10n.SendView.networkFee)
                                        .vendanoFont(.body, size: 16)
                                        .foregroundColor(theme.color(named: "TextPrimary"))

                                    Spacer()

                                    if feeLoading {
                                        ProgressView()
                                            .progressViewStyle(
                                                CircularProgressViewStyle(
                                                    tint: theme.color(named: "Accent")
                                                )
                                            )
                                    } else if netFee > 0 {
                                        Text("\((netFee).formatted(.number.precision(.fractionLength(2)))) ₳")
                                            .vendanoFont(.body, size: 16)
                                            .foregroundColor(theme.color(named: "TextPrimary"))
                                    } else if feeError != nil {
                                        Text(L10n.SendView.text)
                                            .vendanoFont(.body, size: 16)
                                            .foregroundColor(theme.color(named: "TextSecondary"))
                                    } else {
                                        Text(L10n.SendView.text)
                                            .vendanoFont(.body, size: 16)
                                            .foregroundColor(theme.color(named: "TextSecondary"))
                                    }
                                }

                                if let err = feeError {
                                    Text(err)
                                        .vendanoFont(.caption, size: 13)
                                        .foregroundColor(theme.color(named: "Negative"))
                                        .padding([.top, .bottom], 8)
                                }
                            }

                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(String(format: String(localized: "SendView.vendanoFeeFormat"),
                                                Config.vendanoAppFeePercentFormatted))
                                        .vendanoFont(.body, size: 16)
                                        .foregroundColor(theme.color(named: "TextPrimary"))
                                    
                                    Spacer()
                                    
                                    Text("\((appFee).formatted(.number.precision(.fractionLength(2)))) ₳")
                                        .vendanoFont(.body, size: 16)
                                        .foregroundColor(theme.color(named: "TextPrimary"))
                                }
                                
                                if appFee == 0 {
                                    Text(L10n.SendView.vendanoFeeWaivedTheCardanoNetworkDoesnT)
                                        .vendanoFont(.caption, size: 13)
                                        .foregroundColor(theme.color(named: "TextSecondary"))
                                        .padding(.top, 4)
                                }
                            }

                            HStack {
                                Text(L10n.SendView.total)
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextPrimary"))

                                Spacer()

                                Text("\((ada + tipValue + netFee + appFee).formatted(.number.precision(.fractionLength(2)))) ₳")
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextPrimary"))
                            }
                        }
                        .listRowBackground(theme.color(named: "CellBackground"))
                    }

                    Section {
                        if recipient != nil || sendMethod == .address {
                            Button {
                                if shouldShowSendAuthPrimer() {
                                    showSendAuthPrimer = true
                                } else {
                                    authenticateAndSend()
                                }
                            } label: {
                                Label(L10n.SendView.sendAda, systemImage: "paperplane.fill")
                                    .vendanoFont(.body, size: 16)
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(!recipientOK || !amountOK)
                            .buttonStyle(PrimaryButtonStyle())
                            .listRowBackground(Color.clear)
                        } else {
                            Button(L10n.SendView.inviteFriend) {
                                let handle: String
                                switch sendMethod {
                                case .email: handle = email.lowercased()
                                case .phone: handle = "\(dialCode) \(localNumber)".trimmingCharacters(in: .whitespaces)
                                default: handle = ""
                                }
                                var adaMsg = adaText
                                if adaMsg == "" { adaMsg = L10n.SendView.userSendingUnknownADAAmount }
                                let msg = L10n.SendView.inviteMessage(
                                    senderName: state.displayName,
                                    adaAmount: adaMsg
                                )

                                shareInvite = ShareMessage(text: msg)

                                Task {
                                    try? await FirebaseService.shared.addPendingContact(handle)
                                }
                            }
                            .disabled(!recipientOK)
                            .buttonStyle(PrimaryButtonStyle())
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollDismissesKeyboard(.interactively)
                .listRowBackground(theme.color(named: "CellBackground"))
                .padding(.bottom, kb.height)
            }
            .task {
                // Apply “send to” draft once when this view appears
                if !didApplyDraft, let addr = state.sendToAddress {
                    didApplyDraft = true

                    // Use Address mode and prefill just the address text
                    sendMethod = .address
                    addressText = addr

                    // Clear the draft so manual Send opens clean next time
                    state.sendToAddress = nil
                } else if sendMethod == .email {
                    // Fallback: normal behavior – focus email field on first open
                    emailFocus = true
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .onChange(of: adaText) { _, _ in recalcFee() }

            if isSending {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView(L10n.SendView.sendingAda)
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 8).fill(theme.color(named: "FieldBackground")))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .alert(L10n.SendView.unknownAddress, isPresented: $showWarning) {
            Button(L10n.Common.cancel, role: .cancel) {}
            Button(L10n.SendView.sendAnyway) {
                authenticateAndSend()
            }
        } message: {
            Text(L10n.SendView.weDonTRecognizeThisAddressInVendano)
                .vendanoFont(.body, size: 16)
                .foregroundColor(theme.color(named: "TextPrimary"))
        }
        // success alert
        .alert(L10n.SendView.adaSent, isPresented: $sendSuccess) {
            Button(L10n.Common.ok, action: onClose)
        } message: {
            Text(L10n.SendView.yourAdaHasBeenSuccessfullySentYouLl)
                .vendanoFont(.body, size: 16)
                .foregroundColor(theme.color(named: "TextPrimary"))
        }
        // generic error alert
        .alert(L10n.SendView.error, isPresented: Binding(
            get: { sendError != nil },
            set: { if !$0 { sendError = nil } }
        )) {
            Button(L10n.Common.ok) { sendError = nil }
        } message: {
            Text(sendError ?? L10n.SendView.sendFailedTryAgain)
                .vendanoFont(.body, size: 16)
                .foregroundColor(theme.color(named: "TextPrimary"))
        }
        // invite‐notfound alert
        .alert(inviteTitle, isPresented: $showInviteAlert) {
            Button(L10n.Common.ok) {}
        } message: {
            Text(inviteMessage)
                .vendanoFont(.body, size: 16)
                .foregroundColor(theme.color(named: "TextPrimary"))
        }
        // Face ID alert
        .alert(L10n.SendView.authPrimerTitle, isPresented: $showSendAuthPrimer) {
            Button(L10n.Common.cancel, role: .cancel) {}
            Button(L10n.Common.continue) {
                didShowSendAuthPrimer = true
                authenticateAndSend()
            }
        } message: {
            Text(L10n.SendView.authPrimerMessage(authMethodName()))
        }
        .sheet(isPresented: $showTapToPay) {
            TapToPayPayerView()
                .environmentObject(theme)
        }
        .sheet(item: $shareInvite) { invitation in
            ZStack {
                LightGradientView()
                    .ignoresSafeArea()

                switch sendMethod {
                case .email:
                    // pop up Mail composer with the address they entered
                    if MFMailComposeViewController.canSendMail() {
                        MailComposeView(
                            recipients: [email],
                            subject: L10n.SendView.inviteEmailSubject,
                            body: invitation.text
                        )
                    } else {
                        Text(L10n.SendView.mailServicesAreNotAvailableOnThisDevice)
                            .vendanoFont(.body, size: 16)
                            .foregroundColor(theme.color(named: "TextPrimary"))
                    }

                case .phone:
                    // pop up SMS composer with the number they entered
                    if MFMessageComposeViewController.canSendText() {
                        MessageComposeView(
                            recipients: [dialCode + localNumber.filter(\.isWholeNumber)],
                            body: invitation.text
                        )
                    } else {
                        Text(L10n.SendView.smsServicesAreNotAvailableOnThisDevice)
                            .vendanoFont(.body, size: 16)
                            .foregroundColor(theme.color(named: "TextPrimary"))
                    }

                case .address:
                    // fallback to generic share sheet when it’s just a raw address
                    ShareActivityView(activityItems: [invitation.text])
                }
            }
            .alert(L10n.SendView.enableNotifications, isPresented: $showNotificationPrompt) {
                Button(L10n.SendView.allow) { requestPushPermission() }
                Button(L10n.Common.notNow, role: .cancel) {}
            } message: {
                Text(L10n.SendView.vendanoUsesNotificationsToLetYouKnowWhen)
                    .vendanoFont(.body, size: 16)
                    .foregroundColor(theme.color(named: "TextPrimary"))
            }
        }
    }
    
    private func shouldShowSendAuthPrimer() -> Bool {
        guard !didShowSendAuthPrimer else { return false }
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err)
    }

    private func authMethodName() -> String {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            return L10n.SendView.authPasscode
        }
        switch ctx.biometryType {
        case .faceID:  return L10n.SendView.authFaceId
        case .touchID: return L10n.SendView.authTouchId
        default:       return L10n.SendView.authBiometrics
        }
    }

    func sanitizeDecimal(_ s: String, maxFractionDigits: Int = 6) -> String {
        // keep only digits and the first “.”
        var filtered = s.filter { "0123456789.".contains($0) }
        let parts = filtered.split(separator: ".", omittingEmptySubsequences: false)
        if parts.count > 1 {
            let intPart = parts[0]
            var fracPart = parts[1]
            if fracPart.count > maxFractionDigits {
                fracPart = fracPart.prefix(maxFractionDigits)
            }
            filtered = "\(intPart).\(fracPart)"
        }
        // if it starts “.”, prefix with “0”
        if filtered.first == "." { filtered = "0" + filtered }
        return filtered
    }

    func requestPushPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    @MainActor
    private func recalcFee() {
        let dest = (recipient?.address ?? addressText)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let ada = Double(adaText),
            ada > 0,
            !dest.isEmpty
        else {
            DebugLogger.log("💸 [fee-ui] recalcFee: cleared (adaText=\(adaText), dest='\(dest)')")
            feeLoading = false
            feeError = nil
            netFee = 0
            return
        }

        let destPreview = dest.count > 20
            ? dest.prefix(10) + "…" + dest.suffix(10)
            : Substring(dest)

        DebugLogger.log("💸 [fee-ui] recalcFee start ada=\(ada) dest=\(destPreview)")

        feeLoading = true
        feeError = nil
        netFee = 0

        Task {
            do {
                let feeAda = try await wallet.estimateNetworkFee(to: dest, ada: ada, tip: tipValue)
                DebugLogger.log("💸 [fee-ui] recalcFee success feeAda=\(feeAda) for ada=\(ada) dest=\(destPreview)")
                netFee = feeAda
                feeError = nil
            } catch {
                DebugLogger.log("💥 [fee-ui] recalcFee error: \(error)")

                if let rustError = error as? CardanoRustError {
                    switch rustError {
                    case let .common(message):
                        DebugLogger.log("💥 [fee-ui] CardanoRustError.common: \(message)")
                        if message.contains("UTxO Balance Insufficient") {
                            feeError = L10n.SendView.notEnoughAdaForTransaction
                        } else {
                            // 👇 this is the string you’re currently seeing
                            feeError = L10n.SendView.couldNotEstimateFeeWithMessage(message)
                        }
                    default:
                        feeError = L10n.SendView.couldNotEstimateFeeTryAgain
                    }
                } else {
                    feeError = L10n.SendView.couldNotEstimateFeeTryAgain
                }

                netFee = 0
            }

            feeLoading = false
        }
    }

    // MARK: – Face ID + send

    private func authenticateAndSend() {
        let ctx = LAContext()
        ctx.localizedCancelTitle = L10n.Common.cancelString

        var authErr: NSError?
        let policy: LAPolicy = .deviceOwnerAuthentication   // ✅ allows passcode fallback

        guard ctx.canEvaluatePolicy(policy, error: &authErr) else {
            Task { await sendTransaction() }
            return
        }

        ctx.evaluatePolicy(policy, localizedReason: L10n.SendView.confirmBeforeSendingReason) { success, error in
            if success {
                Task { await sendTransaction() }
            } else {
                Task { @MainActor in
                    if let laError = error as? LAError {
                        switch laError.code {
                        case .userCancel, .systemCancel, .appCancel:
                            // user backed out — no need to scare them with “error”
                            return
                        case .biometryLockout:
                            sendError = L10n.SendView.authLockedFormat(authMethodName().capitalized)
                        default:
                            sendError = L10n.SendView.authFailed
                        }
                    } else {
                        sendError = L10n.SendView.authFailed
                    }
                }
            }
        }
    }

    @MainActor
    private func sendTransaction() async {
        isSending = true
        defer { isSending = false }

        guard let amount = Double(adaText), amount > 0 else {
            sendError = L10n.SendView.enterValidAmount
            return
        }
        let tip = Double(tipText) ?? 0

        let dest = (recipient?.address ?? addressText)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            // 🔒 HARD GATE: don’t try to send more than the chain will accept
            let maxAda = try await WalletService.shared
                .maxSendableAda(to: dest, tipAda: tip)

            if amount > maxAda {
                let formatted = (maxAda).formatted(.number.precision(.fractionLength(6)))
                sendError = L10n.SendView.maxSendableDueToTokens(formatted)
                return
            }

            let txHash = try await WalletService.shared.sendMultiTransaction(
                to: dest,
                amount: amount,
                tip: tip
            )

            Task { @MainActor in
                state.refreshOnChainData()
            }

            AnalyticsManager.logEvent("send_success", parameters: ["amount": amount])
            sendSuccess = true

            await FirebaseService.shared.recordTransaction(
                recipientAddress: dest,
                amount: amount,
                txHash: txHash
            )
        } catch {
            var friendly = error.localizedDescription

            // 🧠 Translate the FeeTooSmallUTxO noise into human language
            let lower = friendly.lowercased()
            if lower.contains("feetoosmallutxo") || (lower.contains("fee") && lower.contains("small")) {
                friendly = L10n.SendView.cardanoRejectedMinAdaWithTokens
            }

            debugPrint("❌ Raw Blockfrost error:", error as Error)
            AnalyticsManager.logEvent("send_failure", parameters: ["errorMsg": friendly])
            sendError = friendly
        }
    }
    
    private func isValidAdaHandle(_ raw: String) -> Bool {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let noDollar = s.hasPrefix("$") ? String(s.dropFirst()) : s
        // allowed: a-z 0-9 . _ -
        let regex = try! NSRegularExpression(pattern: "^[a-z0-9._-]{1,15}$")
        return regex.firstMatch(in: noDollar.lowercased(), range: NSRange(location: 0, length: noDollar.count)) != nil
    }

    private func lookupRecipient() {
        lookupTask?.cancel()

        lookupTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)

            let handle: String
            switch sendMethod {
            case .email:
                guard emailOK else {
                    recipient = nil
                    return
                }
                handle = email.lowercased()

            case .phone:
                let digits = localNumber.filter(\.isWholeNumber)
                guard phoneOK else {
                    recipient = nil
                    return
                }
                handle = "\(dialCode)\(digits)"
                
            case .address:
                let input = addressText.trimmingCharacters(in: .whitespacesAndNewlines)

                // If it looks like a raw address, require normal validation
                if input.hasPrefix("addr") || input.hasPrefix("stake") {
                    guard isValidCardanoAddress(input) else { recipient = nil; return }
                    // If you still want to pull Vendano profile data for known addresses, keep this:
                    if let (name, avatarURL, chainAddr) = await FirebaseService.shared.fetchRecipient(for: input) {
                        recipient = Recipient(name: name, avatarURL: avatarURL, address: chainAddr)
                    } else {
                        // show bare address but still allow sending
                        recipient = Recipient(name: L10n.SendView.recipientCardanoAddress, avatarURL: nil, address: input)
                    }
                    recalcFee()
                    return
                }

                // Otherwise treat as ADA Handle (with or without $)
                guard isValidAdaHandle(input) else { recipient = nil; return }

                if let chainAddr = try? await wallet.resolveAdaHandle(input) {
                    let display = input.hasPrefix("$") ? input : "$" + input
                    recipient = Recipient(name: display.lowercased(), avatarURL: nil, address: chainAddr)
                    recalcFee()
                } else {
                    recipient = nil // unknown / not found
                }
                return

            }

            if let (name, avatarURL, chainAddr) = await FirebaseService.shared.fetchRecipient(for: handle) {
                AnalyticsManager.logEvent("send_lookup_success", parameters: ["type": sendMethod])
                recipient = Recipient(name: name, avatarURL: avatarURL, address: chainAddr)
                recalcFee()
            } else {
                recipient = nil
            }
        }
    }
    
    @MainActor
    private func fillMaxAmount() async {
        let dest = (recipient?.address ?? addressText)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !dest.isEmpty else { return }

        do {
            let maxAda = try await WalletService.shared
                .maxSendableAda(to: dest, tipAda: tipValue)

            adaText = (maxAda).formatted(.number.precision(.fractionLength(6)))
            recalcFee()
        } catch {
            DebugLogger.log("⚠️ Failed to compute max sendable ADA: \(error)")
            feeError = L10n.SendView.couldNotCalculateMaxSendable
        }
    }

}

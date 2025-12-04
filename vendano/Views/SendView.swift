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
    case email = "Email"
    case phone = "Phone"
    case address = "Address"
    var id: String { rawValue }
}

struct SendView: View {
    @EnvironmentObject var theme: VendanoTheme

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
                    Section(header: Text("To")
                        .vendanoFont(.headline, size: 18, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))
                    ) {
                        Picker("", selection: $sendMethod) {
                            ForEach(SendMethod.allCases) { method in
                                Text(method.rawValue)
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
                            TextField("you\u{200B}@example.com", text: $email)
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
                                TextField("+1", text: $dialCode)
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
                                TextField("5551234567", text: $localNumber)
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
                            TextField("Paste a Cardano address or $handle", text: $addressText)
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

                    Section(header: Text("Amount")
                        .vendanoFont(.headline, size: 18, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))
                    ) {
                        HStack {
                            TextField("0.0 ₳", text: $adaText)
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
                                Text("₳ ≈ \(wallet.fiatCurrency.symbol)\(ada * fiatRate, specifier: "%.2f")")
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextSecondary"))
                            }

                            Button("All") {
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

                                adaText = String(format: "%.6f", maxAmount)

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
                            Toggle("Add a tip for the developer", isOn: $includeTip)
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
                                    TextField("0.00", text: $tipText)
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

                                    Text("₳ Tip amount")
                                        .vendanoFont(.body, size: 16)
                                        .foregroundColor(theme.color(named: "TextPrimary"))
                                }
                                .padding(.vertical, 4)

                                Text("Network fees cover basic blockchain costs; any extra tip helps us keep this app running and is greatly appreciated!")
                                    .vendanoFont(.caption, size: 14)
                                    .foregroundColor(theme.color(named: "TextSecondary"))
                                    .padding()
                            }
                        }
                    }
                    .listRowBackground(theme.color(named: "CellBackground"))

                    if let ada = adaValue, ada > 0 {
                        Section(header: Text("Summary")
                            .vendanoFont(.headline, size: 18, weight: .semibold)
                            .foregroundColor(theme.color(named: "TextReversed"))
                        ) {
                            HStack {
                                Text("Amount")
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextPrimary"))

                                Spacer()

                                Text("\(ada, specifier: "%.2f") ₳")
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextPrimary"))
                            }

                            if tipValue > 0 {
                                HStack {
                                    Text("Tip")
                                        .vendanoFont(.body, size: 16)
                                        .foregroundColor(theme.color(named: "TextPrimary"))

                                    Spacer()

                                    Text("\(tipValue, specifier: "%.2f") ₳")
                                        .vendanoFont(.body, size: 16)
                                        .foregroundColor(theme.color(named: "TextPrimary"))
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Network fee")
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
                                        Text("\(netFee, specifier: "%.2f") ₳")
                                            .vendanoFont(.body, size: 16)
                                            .foregroundColor(theme.color(named: "TextPrimary"))
                                    } else if feeError != nil {
                                        Text("—")
                                            .vendanoFont(.body, size: 16)
                                            .foregroundColor(theme.color(named: "TextSecondary"))
                                    } else {
                                        Text("—")
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
                                    Text("Vendano fee (\(Config.vendanoAppFeePercentFormatted))")
                                        .vendanoFont(.body, size: 16)
                                        .foregroundColor(theme.color(named: "TextPrimary"))
                                    
                                    Spacer()
                                    
                                    Text("\(appFee, specifier: "%.2f") ₳")
                                        .vendanoFont(.body, size: 16)
                                        .foregroundColor(theme.color(named: "TextPrimary"))
                                }
                                
                                if appFee == 0 {
                                    Text("Vendano fee waived - the Cardano network doesn't allow amounts smaller than 1 ADA.")
                                        .vendanoFont(.caption, size: 13)
                                        .foregroundColor(theme.color(named: "TextSecondary"))
                                        .padding(.top, 4)
                                }
                            }

                            HStack {
                                Text("Total")
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextPrimary"))

                                Spacer()

                                Text("\(ada + tipValue + netFee + appFee, specifier: "%.2f") ₳")
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextPrimary"))
                            }
                        }
                        .listRowBackground(theme.color(named: "CellBackground"))
                    }

                    Section {
                        if recipient != nil || sendMethod == .address {
                            Button {
                                authenticateAndSend()
                            } label: {
                                Label("Send ADA", systemImage: "paperplane.fill")
                                    .vendanoFont(.body, size: 16)
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(!recipientOK || !amountOK)
                            .buttonStyle(PrimaryButtonStyle())
                            .listRowBackground(Color.clear)
                        } else {
                            Button("Invite Friend") {
                                let handle: String
                                switch sendMethod {
                                case .email: handle = email.lowercased()
                                case .phone: handle = "\(dialCode) \(localNumber)".trimmingCharacters(in: .whitespaces)
                                default: handle = ""
                                }
                                var adaMsg = adaText
                                if adaMsg == "" { adaMsg = "some" }
                                let msg = """
                                \(state.displayName) wants to send you \(adaMsg) ADA on the Cardano blockchain. Please download the Vendano app at https://vendano.net to get started!
                                """

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
                if sendMethod == .email {
                    emailFocus = true
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .onChange(of: adaText) { _, _ in recalcFee() }

            if isSending {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView("Sending ADA...")
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 8).fill(theme.color(named: "FieldBackground")))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .alert("Unknown Address", isPresented: $showWarning) {
            Button("Cancel", role: .cancel) {}
            Button("Send Anyway") {
                authenticateAndSend()
            }
        } message: {
            Text("We don’t recognize this address in Vendano (which is fine, if you know this person). Once ADA is sent, it can’t be undone - so please double-check everything before you continue.")
                .vendanoFont(.body, size: 16)
                .foregroundColor(theme.color(named: "TextPrimary"))
        }
        // success alert
        .alert("🎉 ADA Sent!", isPresented: $sendSuccess) {
            Button("OK", action: onClose)
        } message: {
            Text("Your ADA has been successfully sent. You’ll see it in your transaction history in a few minutes (once the blockchain updates).")
                .vendanoFont(.body, size: 16)
                .foregroundColor(theme.color(named: "TextPrimary"))
        }
        // generic error alert
        .alert("Error", isPresented: Binding(
            get: { sendError != nil },
            set: { if !$0 { sendError = nil } }
        )) {
            Button("OK") { sendError = nil }
        } message: {
            Text(sendError ?? "Something went wrong and your ADA wasn’t sent. Please try again in a moment.")
                .vendanoFont(.body, size: 16)
                .foregroundColor(theme.color(named: "TextPrimary"))
        }
        // invite‐notfound alert
        .alert(inviteTitle, isPresented: $showInviteAlert) {
            Button("OK") {}
        } message: {
            Text(inviteMessage)
                .vendanoFont(.body, size: 16)
                .foregroundColor(theme.color(named: "TextPrimary"))
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
                            subject: "You’ve been invited to Vendano!",
                            body: invitation.text
                        )
                    } else {
                        Text("Mail services are not available on this device.")
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
                        Text("SMS services are not available on this device.")
                            .vendanoFont(.body, size: 16)
                            .foregroundColor(theme.color(named: "TextPrimary"))
                    }

                case .address:
                    // fallback to generic share sheet when it’s just a raw address
                    ShareActivityView(activityItems: [invitation.text])
                }
            }
            .onAppear {
                checkNotificationPermission()
            }
            .alert("Enable Notifications?", isPresented: $showNotificationPrompt) {
                Button("Allow") { requestPushPermission() }
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("Vendano uses notifications to let you know when friends join or send you ADA.")
                    .vendanoFont(.body, size: 16)
                    .foregroundColor(theme.color(named: "TextPrimary"))
            }
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

    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                DispatchQueue.main.async {
                    showNotificationPrompt = true
                }
            }
        }
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
                            feeError = "There is not enough ADA in your wallet to cover this transaction."
                        } else {
                            // 👇 this is the string you’re currently seeing
                            feeError = "Couldn’t estimate the fee: \(message)"
                        }
                    default:
                        feeError = "Couldn’t estimate the fee. Please try again."
                    }
                } else {
                    feeError = "Couldn’t estimate the fee. Please try again."
                }

                netFee = 0
            }

            feeLoading = false
        }
    }

    // MARK: – Face ID + send

    private func authenticateAndSend() {
        let ctx = LAContext()
        var authErr: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authErr) {
            ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Let's confirm it’s you before you send ADA from your wallet."
            ) { success, _ in
                if success {
                    Task { await sendTransaction() }
                }
            }
        } else {
            Task { await sendTransaction() }
        }
    }

    @MainActor
    private func sendTransaction() async {
        isSending = true
        defer { isSending = false }

        guard let amount = Double(adaText), amount > 0 else {
            sendError = "Enter a valid amount (more than 0)."
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
                let formatted = String(format: "%.6f", maxAda)
                sendError =
                """
                Because this wallet is holding tokens that need ADA to stay with them,
                you can currently send up to \(formatted) ADA from this wallet.
                Try entering a smaller amount or use the “All” button.
                """
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
            if lower.contains("feettoosmallutxo") {
                friendly =
                """
                Cardano rejected this transaction because the ADA left behind with your tokens
                would fall below the minimum the network allows. In practice, that means you’re
                trying to send a bit more ADA than this wallet can safely spare while still
                holding all of those tokens. Try sending a smaller amount or use the “All” button.
                """
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
                        recipient = Recipient(name: "Cardano Address", avatarURL: nil, address: input)
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

            adaText = String(format: "%.6f", maxAda)
            recalcFee()
        } catch {
            DebugLogger.log("⚠️ Failed to compute max sendable ADA: \(error)")
            feeError = "Couldn't calculate the maximum amount you can send right now."
        }
    }

}

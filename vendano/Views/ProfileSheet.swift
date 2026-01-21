//
//  ProfileSheet.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/7/25.
//

import LocalAuthentication
import PhotosUI
import SwiftUI
import UIKit
import UserNotifications

struct ProfileSheet: View {
    @EnvironmentObject var theme: VendanoTheme

    @StateObject private var state = AppState.shared
    @StateObject private var wallet = WalletService.shared

    @Environment(\.dismiss) private var dismiss

    @AppStorage("appearancePreference") private var appearancePrefRaw = AppearancePreference.system.rawValue

    private var appearancePref: AppearancePreference {
        AppearancePreference(rawValue: appearancePrefRaw) ?? .system
    }

    @State private var authPurpose: ContactMethod?
    @State private var name = ""
    @State private var originalName = ""
    @State private var originalStoreName = ""

    @State private var pickerItem: PhotosPickerItem?
    @State private var pickerPresented = false
    @State private var avatar: Image?
    @State private var showDel = false
    @State private var textChanged = false
    @State private var uploading = false

    @State private var useHoskyTheme = false
    @State private var suppressAppearanceReset = false

    @State private var notificationStatus: UNAuthorizationStatus?
    @State private var showNotificationsDeniedAlert = false

    @FocusState private var focus: Bool

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()

                    Button(textChanged ? L10n.Common.save : L10n.Common.done) {
                        if textChanged {
                            Task {
                                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                                let trimmedStore = state.storeName.trimmingCharacters(in: .whitespacesAndNewlines)

                                let nameChanged = trimmedName != originalName
                                let storeChanged = trimmedStore != originalStoreName

                                do {
                                    if nameChanged {
                                        try await FirebaseService.shared.updateDisplayName(trimmedName)
                                        state.displayName = trimmedName
                                        originalName = trimmedName
                                    }

                                    if storeChanged {
                                        try await FirebaseService.shared.updateStoreName(trimmedStore)
                                        originalStoreName = trimmedStore
                                    }

                                    textChanged = false
                                } catch {
                                    DebugLogger.log("⚠️ Failed to save profile name/store name: \(error)")
                                }

                                dismiss()
                            }
                        } else {
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || uploading)
                    .tint(theme.color(named: "TextReversed"))
                    .vendanoFont(.body, size: 16, weight: .semibold)
                    .padding()
                }
                .padding()

                Form {
                    Section(
                        header:
                        Text(L10n.ProfileSheet.namePhoto)
                            .vendanoFont(.headline, size: 18, weight: .semibold)
                            .foregroundColor(theme.color(named: "TextReversed"))
                    ) {
                        HStack(spacing: 16) {
                            AvatarThumb(
                                localImage: state.avatar,
                                url: URL(string: state.avatarUrl ?? ""),
                                name: state.displayName,
                                size: 72,
                                tap: { pickerPresented = true }
                            )
                            .frame(width: 72, height: 72)
                            .photosPicker(
                                isPresented: $pickerPresented,
                                selection: $pickerItem,
                                matching: .images,
                                photoLibrary: .shared()
                            )
                            .onChange(of: pickerItem) { _, _ in
                                guard let item = pickerItem else { return }
                                uploading = true
                                Task {
                                    await state.uploadAvatar(from: item)
                                    uploading = false
                                }
                            }
                            .disabled(uploading)

                            TextField(L10n.ProfileSheet.displayName, text: $name)
                                .vendanoFont(.body, size: 18)
                                .foregroundColor(theme.color(named: "TextSecondary"))
                                .padding(12)
                                .background(theme.color(named: "FieldBackground"))
                                .cornerRadius(8)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.words)
                                .focused($focus)
                                .onChange(of: name) { _, _ in
                                    textChanged = true
                                }
                        }
                    }
                    .listRowBackground(theme.color(named: "CellBackground"))

                    Section(
                        header:
                        Text(L10n.ProfileSheet.logins)
                            .vendanoFont(.headline, size: 18, weight: .semibold)
                            .foregroundColor(theme.color(named: "TextReversed"))
                    ) {
                        ForEach(state.email, id: \.self) { handle in
                            HStack {
                                Text(handle)
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextPrimary"))

                                Spacer()

                                Button(role: .destructive) {
                                    state.removeEmail(handle)
                                } label: { Image(systemName: "trash") }
                                    .disabled(state.email.count == 1)
                            }
                        }
                        Button(L10n.ProfileSheet.addEmail) { authPurpose = .email }

                        ForEach(state.phone, id: \.self) { handle in
                            HStack {
                                Text(handle)
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextPrimary"))

                                Spacer()
                            }
                        }
                        if state.phone.isEmpty {
                            Button(L10n.ProfileSheet.addPhone) { authPurpose = .phone }
                        }
                    }
                    .listRowBackground(theme.color(named: "CellBackground"))

                    Section(header: Text(L10n.ProfileSheet.appearance)
                        .vendanoFont(.headline, size: 18, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))
                    ) {
                        Picker(L10n.ProfileSheet.appearance, selection: $appearancePrefRaw) {
                            ForEach(AppearancePreference.allCases) { option in
                                Text(option.displayName)
                                    .vendanoFont(.body, size: 16)
                                    .tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        if wallet.hoskyBalance > 0 {
                            Toggle(L10n.ProfileSheet.hoskyfyMyApp, isOn: $useHoskyTheme)
                                .toggleStyle(SwitchToggleStyle(tint: theme.color(named: "Accent")))
                                .vendanoFont(.body, size: 16)
                                .foregroundColor(theme.color(named: "TextPrimary"))
                        }
                    }
                    .listRowBackground(theme.color(named: "CellBackground"))

                    Section(
                        header:
                        Text(L10n.StoreView.storeSettings)
                            .vendanoFont(.headline, size: 18, weight: .semibold)
                            .foregroundColor(theme.color(named: "TextReversed"))
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.StoreView.storeName)
                                .vendanoFont(.caption, size: 13, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextSecondary"))
                            TextField(L10n.StoreView.storeNamePlaceholder, text: $state.storeName)
                                .textInputAutocapitalization(.words)
                                .submitLabel(.done)
                                .vendanoFont(.body, size: 16)
                                .foregroundColor(theme.color(named: "TextPrimary"))
                                .padding(12)
                                .background(theme.color(named: "FieldBackground"))
                                .cornerRadius(10)
                                .onChange(of: state.storeName) { _, _ in
                                    textChanged = true
                                }

                        }
                        .padding(.vertical, 6)

                        Picker(L10n.StoreView.defaultPricingCurrency, selection: $state.storeDefaultPricingCurrency) {
                            Text(L10n.StoreView.defaultPricingLocalCurrency).tag(PricingCurrency.fiat)
                            Text(L10n.StoreView.defaultPricingAda).tag(PricingCurrency.ada)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(L10n.StoreView.exchangeRateBuffer)
                                Spacer()
                                Text(L10n.StoreView.percentValue(Int((state.storeExchangeRateBufferPercent * 100).rounded())))
                                    .foregroundColor(theme.color(named: "TextSecondary"))
                            }
                            .vendanoFont(.body, size: 16)

                            Slider(value: $state.storeExchangeRateBufferPercent, in: 0 ... 0.25, step: 0.01)
                                .tint(theme.color(named: "Accent"))

                            Text(L10n.StoreView.exchangeRateBufferHelp)
                                .vendanoFont(.caption, size: 13)
                                .foregroundColor(theme.color(named: "TextSecondary"))
                        }
                        .padding(.vertical, 6)

                        Toggle(L10n.StoreView.enableTips, isOn: $state.storeTipsEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: theme.color(named: "Accent")))
                            .vendanoFont(.body, size: 16)
                            .foregroundColor(theme.color(named: "TextPrimary"))
                    }
                    .listRowBackground(theme.color(named: "CellBackground"))

                    Section(
                        header:
                        Text(L10n.ProfileSheet.advanced)
                            .vendanoFont(.headline, size: 18, weight: .semibold)
                            .foregroundColor(theme.color(named: "TextReversed"))
                    ) {
                        Button {
                            Task {
                                let status = await NotificationPermissionManager.shared.getStatus()
                                notificationStatus = status

                                switch status {
                                case .notDetermined:
                                    let granted = await NotificationPermissionManager.shared.request()
                                    notificationStatus = await NotificationPermissionManager.shared.getStatus()
                                    if !granted {
                                        // user tapped "Don't Allow" on the system prompt
                                        showNotificationsDeniedAlert = true
                                    }

                                case .denied:
                                    showNotificationsDeniedAlert = true

                                case .authorized, .provisional, .ephemeral:
                                    // already enabled; optionally do nothing or show a confirmation toast
                                    break

                                @unknown default:
                                    break
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "bell")
                                Text(L10n.ProfileSheet.notificationsTitle)

                                Spacer()

                                Text(notificationLabel(notificationStatus))
                                    .foregroundStyle(.secondary)

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .alert(L10n.ProfileSheet.enableNotifications, isPresented: $showNotificationsDeniedAlert) {
                            Button(L10n.ProfileSheet.openSettings) {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            Button(L10n.Common.cancel, role: .cancel) {}
                        } message: {
                            Text(L10n.ProfileSheet.notificationsOff)
                        }

                        /*
                         Toggle(L10n.ProfileSheet.showStakingRewardsDetails, isOn: $state.isExpertMode)
                             .toggleStyle(SwitchToggleStyle(tint: theme.color(named: "Accent")))
                             .vendanoFont(.body, size: 16)
                             .foregroundColor(theme.color(named: "TextPrimary"))
                          */

                        Picker(L10n.ProfileSheet.currency, selection: $wallet.fiatCurrency) {
                            ForEach(FiatCurrency.allCases) { currency in
                                Text(currency.displayName)
                                    .vendanoFont(.body, size: 16)
                                    .tag(currency)
                            }
                        }
                    }
                    .listRowBackground(theme.color(named: "CellBackground"))
                    .onChange(of: wallet.fiatCurrency) { _, _ in
                        Task {
                            await wallet.loadPrice()
                        }
                    }

                    Section(
                        header:
                        Text(L10n.ProfileSheet.dangerZone)
                            .vendanoFont(.headline, size: 18, weight: .semibold)
                            .foregroundColor(theme.color(named: "TextReversed"))
                    ) {
                        Button(L10n.ProfileSheet.deleteAccount, role: .destructive) {
                            showDel = true
                        }
                        .vendanoFont(.body, size: 16)
                        .foregroundColor(theme.color(named: "TextReversed"))
                    }
                    .listRowBackground(theme.color(named: "Negative"))
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .onAppear {
                    name = state.displayName
                    originalName = state.displayName
                    originalStoreName = state.storeName

                    avatar = state.avatar
                    focus = true
                }
                .onReceive(NotificationCenter.default.publisher(for: .didCompleteContactAuth)) { _ in
                    authPurpose = nil
                }
                .sheet(item: $authPurpose) { purpose in
                    NewContactAuthView(method: purpose) {
                        authPurpose = nil
                    }
                    .presentationDetents([.fraction(0.4)])
                }
                .alert(L10n.ProfileSheet.deleteAccountConfirm,
                       isPresented: $showDel,
                       actions: {
                           Button(L10n.Common.cancel, role: .cancel) {}
                           Button(L10n.Common.delete, role: .destructive) {
                               authenticateAndDelete()
                           }
                       }, message: {
                           Text(L10n.ProfileSheet.thisRemovesYourNamePictureAndProfileInfo)
                               .vendanoFont(.body, size: 16)
                       })
            }
            .onAppear {
                useHoskyTheme = UserDefaults.standard.bool(forKey: "useHoskyTheme")
            }
            .onChange(of: useHoskyTheme) { _, new in
                UserDefaults.standard.set(new, forKey: "useHoskyTheme")
                if new {
                    suppressAppearanceReset = true
                    appearancePrefRaw = AppearancePreference.system.rawValue
                    VendanoTheme.shared.currentPalette = .hosky
                    AnalyticsManager.logEvent("hosky_mode_activate")
                    guard UIApplication.shared.alternateIconName != "hosky-icon" else { return }

                    UIApplication.shared.setAlternateIconName("hosky-icon") { error in
                        if let error = error {
                            DebugLogger.log("Failed request to update the app’s icon: \(error)")
                        }
                    }
                } else {
                    UIApplication.shared.setAlternateIconName(nil)
                    VendanoTheme.shared.currentPalette =
                        (appearancePref == .dark ? .dark : .light)
                }
            }
            .onChange(of: appearancePrefRaw) { _, _ in
                if suppressAppearanceReset {
                    suppressAppearanceReset = false
                    return
                }
                useHoskyTheme = false
                switch appearancePref {
                case .light:
                    VendanoTheme.shared.currentPalette = .light
                case .dark:
                    VendanoTheme.shared.currentPalette = .dark
                case .system:
                    let style = UITraitCollection.current.userInterfaceStyle
                    VendanoTheme.shared.currentPalette = (style == .dark ? .dark : .light)
                }
            }
            .preferredColorScheme(resolvedScheme())
        }
        .task {
            notificationStatus = await NotificationPermissionManager.shared.getStatus()
        }
    }

    private func notificationLabel(_ status: UNAuthorizationStatus?) -> String {
        guard let status else { return L10n.Common.ellipsis }
        switch status {
        case .authorized, .provisional, .ephemeral:
            return L10n.Common.on
        case .denied:
            return L10n.Common.off
        case .notDetermined:
            return L10n.Common.setUp
        @unknown default:
            return L10n.Common.ellipsis
        }
    }

    private func authenticateAndDelete() {
        let ctx = LAContext()
        var authErr: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authErr) {
            ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: L10n.ProfileSheet.confirmIdentityBeforeDeleteReason
            ) { success, _ in
                if success {
                    Task { await state.nukeAccount() }
                }
            }
        } else {
            Task { await state.nukeAccount() }
        }
    }

    private func resolvedScheme() -> ColorScheme? {
        switch appearancePref {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

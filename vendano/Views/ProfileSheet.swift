//
//  ProfileSheet.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/7/25.
//

import LocalAuthentication
import PhotosUI
import SwiftUI

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
    @State private var pickerItem: PhotosPickerItem?
    @State private var pickerPresented = false
    @State private var avatar: Image?
    @State private var showDel = false
    @State private var textChanged = false
    @State private var uploading = false

    @State private var useHoskyTheme = false
    @State private var suppressAppearanceReset = false

    @FocusState private var focus: Bool

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()

                    Button(textChanged ? "Save" : "Done") {
                        if textChanged {
                            Task {
                                do {
                                    try await FirebaseService.shared.updateDisplayName(name)
                                    state.displayName = name
                                } catch {
                                    DebugLogger.log("⚠️ Failed to save name: \(error)")
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
                        Text("Name & photo")
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

                            TextField("Display name", text: $name)
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
                        Text("Logins")
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
                        Button("Add Email") { authPurpose = .email }

                        ForEach(state.phone, id: \.self) { handle in
                            HStack {
                                Text(handle)
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextPrimary"))

                                Spacer()
                            }
                        }
                        if state.phone.isEmpty {
                            Button("Add Phone") { authPurpose = .phone }
                        }
                    }
                    .listRowBackground(theme.color(named: "CellBackground"))

                    Section(header: Text("Appearance")
                        .vendanoFont(.headline, size: 18, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))
                    ) {
                        Picker("Appearance", selection: $appearancePrefRaw) {
                            ForEach(AppearancePreference.allCases) { option in
                                Text(option.displayName)
                                    .vendanoFont(.body, size: 16)
                                    .tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        if wallet.hoskyBalance > 0 {
                            Toggle("HOSKYfy my app", isOn: $useHoskyTheme)
                                .toggleStyle(SwitchToggleStyle(tint: theme.color(named: "Accent")))
                                .vendanoFont(.body, size: 16)
                                .foregroundColor(theme.color(named: "TextPrimary"))
                        }
                    }
                    .listRowBackground(theme.color(named: "CellBackground"))

                    Section(
                        header:
                        Text("Danger Zone")
                            .vendanoFont(.headline, size: 18, weight: .semibold)
                            .foregroundColor(theme.color(named: "TextReversed"))
                    ) {
                        Button("Delete account", role: .destructive) {
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
                .alert("Delete account?",
                       isPresented: $showDel,
                       actions: {
                           Button("Cancel", role: .cancel) {}
                           Button("Delete", role: .destructive) {
                               authenticateAndDelete()
                           }
                       }, message: {
                           Text("This removes your name, picture, and profile info from our app and database. You won’t be searchable here until you register again, but your wallet and ADA stay safe on the blockchain. You can always recover your funds in this or any other wallet using your 12/15/24-word recovery phrase.")
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
                    guard UIApplication.shared.alternateIconName != "hosky-icon" else { return }

                    UIApplication.shared.setAlternateIconName("hosky-icon") { error in
                        if let error = error {
                            print("Failed request to update the app’s icon: \(error)")
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
    }
    
    private func authenticateAndDelete() {
        let ctx = LAContext()
        var authErr: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authErr) {
            ctx.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Let's confirm it’s you before we remove your account."
            )
            { success, _ in
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

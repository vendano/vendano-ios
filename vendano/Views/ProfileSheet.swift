//
//  ProfileSheet.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/7/25.
//

import PhotosUI
import SwiftUI

struct ProfileSheet: View {
    @StateObject private var state = AppState.shared
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
                    .tint(Color("TextReversed"))
                    .font(.system(size: 16, weight: .semibold))
                    .padding()
                }
                .padding()

                Form {
                    Section(
                        header:
                        Text("Name & photo")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("TextReversed"))
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
                                .font(.system(size: 16))
                                .foregroundColor(Color("TextPrimary"))
                                .padding(12)
                                .cornerRadius(8)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.words)
                                .focused($focus)
                                .onChange(of: name) { _, _ in
                                    textChanged = true
                                }
                        }
                    }

                    Section(
                        header:
                        Text("Logins")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("TextReversed"))
                    ) {
                        ForEach(state.email, id: \.self) { handle in
                            HStack {
                                Text(handle)
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
                                Spacer()
                            }
                        }
                        if state.phone.isEmpty {
                            Button("Add Phone") { authPurpose = .phone }
                        }
                    }

                    Section(header:
                        Text("Appearance")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("TextReversed"))
                    ) {
                        Picker("Appearance", selection: $appearancePrefRaw) {
                            ForEach(AppearancePreference.allCases) { option in
                                Text(option.displayName).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section(
                        header:
                        Text("Danger Zone")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("TextReversed"))
                    ) {
                        Button("Delete account", role: .destructive) {
                            showDel = true
                        }
                    }
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
                               Task {
                                   await state.nukeAccount()
                               }
                           }
                       },
                       message: {
                           Text("This removes your name, picture, and profile info from our app and database. You won’t be searchable here until you register again, but your wallet and ADA stay safe on the blockchain. You can always recover your funds in this or any other wallet using your 24-word recovery phrase.")
                       })
            }
            .preferredColorScheme(resolvedScheme())
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

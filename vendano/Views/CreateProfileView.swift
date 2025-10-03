//
//  CreateProfileView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import PhotosUI
import SwiftUI

struct CreateProfileView: View {
    @EnvironmentObject var theme: VendanoTheme
    @StateObject var state = AppState.shared

    @State private var name: String = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var pickerPresented = false
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Tell us about you")
                        .vendanoFont(.title, size: 24, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))

                    Text("Add a name and picture so senders can be sure it’s you.")
                        .vendanoFont(.body, size: 16)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(theme.color(named: "TextReversed").opacity(0.85))
                        .padding(.horizontal, 24)
                }

                HStack(spacing: 20) {
                    AvatarThumb(
                        localImage: state.avatar,
                        url: URL(string: state.avatarUrl ?? ""),
                        name: state.displayName,
                        size: 72,
                        tap: { pickerPresented = true }
                    )
                    .frame(width: 100, height: 100)
                    .photosPicker(
                        isPresented: $pickerPresented,
                        selection: $pickerItem,
                        matching: .images
                    )

                    TextField("Your name", text: $name)
                        .vendanoFont(.body, size: 18)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.words)
                        .focused($nameFieldFocused)
                        .padding(.trailing, 24)
                }
                .padding()

                Spacer()

                Button {
                    state.displayName = name
                    Task {
                        do {
                            try await FirebaseService.shared.updateDisplayName(name)
                        } catch {
                            DebugLogger.log("⚠️ Failed to save name: \(error.localizedDescription)")
                        }
                    }
                    state.onboardingStep = .walletChoice
                } label: {
                    Text("Continue")
                        .vendanoFont(.body, size: 16)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CapsuleButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 24)

                Spacer(minLength: 20)
            }
            .padding(.vertical, 40)
        }
        .onChange(of: pickerItem) { _, newItem in
            guard let item = newItem else { return }
            Task {
                await state.uploadAvatar(from: item)
            }
        }
        .onAppear {
            nameFieldFocused = true
        }
        .onChange(of: name) { _, new in
            state.displayName = new
        }
    }
}

 #Preview {
    CreateProfileView()
         .environmentObject(VendanoTheme.shared)
 }

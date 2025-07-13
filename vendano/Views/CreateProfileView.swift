//
//  CreateProfileView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import PhotosUI
import SwiftUI

struct CreateProfileView: View {
    @ObservedObject var state = AppState.shared

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

                // ① Title + blurb
                VStack(spacing: 8) {
                    Text("Tell us about you")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("TextReversed"))

                    Text("Add a name and picture so senders can be sure it’s you.")
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color("TextReversed").opacity(0.85))
                        .padding(.horizontal, 24)
                }

                // ② Avatar + name field
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
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.words)
                        .focused($nameFieldFocused)
                        .padding(.trailing, 24)
                }
                .padding()

                Spacer()

                // ③ Continue button
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
}

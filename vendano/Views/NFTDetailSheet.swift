//
//  NFTDetailSheet.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/23/25.
//

import SwiftUI

struct NFTDetailSheet: View {
    let nft: NFT

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: VendanoTheme
    @StateObject private var state = AppState.shared

    @State private var isUploading = false

    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: nft.imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case let .success(img):
                    img.resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                @unknown default: EmptyView()
                }
            }
            .frame(maxHeight: 300)

            Text(nft.name)
                .vendanoFont(.headline, size: 20)
                .foregroundColor(theme.color(named: "TextPrimary"))

            if let desc = nft.description {
                Text(desc)
                    .vendanoFont(.body, size: 16)
                    .foregroundColor(theme.color(named: "TextSecondary"))
            }

            Spacer()

            Button {
                Task {
                    isUploading = true
                    do {
                        // download image
                        let (data, _) = try await URLSession.shared.data(from: nft.imageURL!)
                        guard let ui = UIImage(data: data) else { return }
                        // upload via your FirebaseService
                        let url = try await FirebaseService.shared.uploadAvatar(ui)
                        // update state
                        state.avatar = Image(uiImage: ui)
                        state.avatarUrl = url.absoluteString
                        dismiss()
                    } catch {
                        print("Avatar upload failed:", error)
                    }
                    isUploading = false
                }
            } label: {
                if isUploading {
                    ProgressView()
                } else {
                    Text("Make this my avatar")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isUploading)
        }
        .padding()
        .background(theme.color(named: "BackgroundEnd"))
        .cornerRadius(16)
        .padding()
    }
}

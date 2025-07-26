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
    let onClose: () -> Void

    @State private var isUploading = false

    var body: some View {
        
        ZStack {
            DarkGradientView().ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.color(named: "TextPrimary").opacity(0.7))
                    }
                }
                
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
                
                if let traits = nft.traits, !traits.isEmpty {
                    let columns = [GridItem(.fixed(120)), GridItem(.fixed(120)), GridItem(.fixed(120))]
                    
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(traits.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            VStack(spacing: 4) {
                                Text(key).bold()
                                Text(value)
                            }
                            .multilineTextAlignment(.center)
                            .vendanoFont(.caption, size: 13)
                            .foregroundColor(theme.color(named: "TextPrimary"))
                            .frame(width: 120, height: 60)
                            .background(theme.color(named: "FieldBackground"))
                            .cornerRadius(12)
                        }
                    }
                    
                }
                
                Spacer()
                
                Button {
                    Task {
                        await MainActor.run { isUploading = true }

                        do {
                            guard let url = nft.imageURL else { return }

                            let (data, _) = try await URLSession.shared.data(from: url)
                            guard let uiImg = UIImage(data: data) else { return }

                            await MainActor.run {
                                AppState.shared.removeImage()
                                AppState.shared.saveImage(img: uiImg)
                                AppState.shared.avatar = Image(uiImage: uiImg)
                            }

                            let remoteURL = try await FirebaseService.shared.uploadAvatar(uiImg)

                            await MainActor.run {
                                AppState.shared.avatarUrl = remoteURL.absoluteString
                                dismiss()
                            }

                        } catch {
                            DebugLogger.log("❌ Avatar upload failed: \(error)")
                        }

                        await MainActor.run { isUploading = false }
                    }
                } label: {
                    if isUploading { ProgressView() }
                    else { Text("Make this my avatar").frame(maxWidth: .infinity) }
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
}

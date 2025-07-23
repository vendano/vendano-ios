//
//  NFTThumbnailCell.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/23/25.
//

import SwiftUI

struct NFTThumbnailCell: View {
    let nft: NFT
    @EnvironmentObject var theme: VendanoTheme

    var body: some View {
        AsyncImage(url: nft.imageURL) { phase in
            switch phase {
            case .empty:
                Color.gray.opacity(0.2)
            case let .success(img):
                img.resizable().scaledToFill()
            case .failure:
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundColor(.gray)
            @unknown default: EmptyView()
            }
        }
        .frame(width: 60, height: 60)
        .background(theme.color(named: "CellBackground"))
        .cornerRadius(8)
        .clipped()
    }
}

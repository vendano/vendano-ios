//
//  NFTThumbnailRow.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/23/25.
//

import SwiftUI

struct NFTThumbnailRow: View {
    @StateObject private var vm = NFTGalleryViewModel()
    @Binding var selectedNFT: NFT?

    // Constants
    private let cellSize: CGFloat = 60
    private let spacing: CGFloat = 12
    private let minSidePadding: CGFloat = 16

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width

            let rawCount = (totalWidth + spacing) / (cellSize + spacing)
            let visibleCount = max(Int(rawCount), 1)

            let contentWidth = CGFloat(visibleCount) * cellSize
                + CGFloat(visibleCount - 1) * spacing

            let sidePadding = max(minSidePadding, (totalWidth - contentWidth) / 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(vm.nfts.prefix(visibleCount)) { nft in
                        NFTThumbnailCell(nft: nft)
                            .onTapGesture { selectedNFT = nft }
                    }
                    ForEach(0 ..< max(0, visibleCount - vm.nfts.count), id: \.self) { _ in
                        PlaceholderCell()
                    }
                }
                .padding(.horizontal, sidePadding)
            }
        }
        .frame(height: cellSize)
        .task { await vm.loadNFTs() }
    }
}

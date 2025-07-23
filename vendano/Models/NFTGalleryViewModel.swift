//
//  NFTGalleryViewModel.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/23/25.
//

import Combine
import SwiftUI

@MainActor
class NFTGalleryViewModel: ObservableObject {
    @Published var nfts: [NFT] = []
    @Published var isLoading = false

    func loadNFTs() async {
        let addr = AppState.shared.walletAddress
        guard !addr.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await NFTService.shared.fetchNFTs(address: addr)
            nfts = fetched
        } catch {
            print("Failed loading NFTs:", error)
        }
    }
}

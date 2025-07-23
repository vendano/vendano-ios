//
//  NFT.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/23/25.
//

import Foundation

/// Represents a Cardano NFT in the app
struct NFT: Identifiable {
    let id: String // policyId + assetName hex
    let name: String // CIP-25 metadata name
    let imageURL: Foundation.URL? // CIP-25 metadata image (ipfs:// or http)
    let description: String? // Optional description
}

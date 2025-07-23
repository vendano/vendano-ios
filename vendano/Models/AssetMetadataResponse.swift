//
//  AssetMetadataResponse.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/23/25.
//

import Foundation

/// Wraps the response from `/assets/{asset}/metadata`
struct AssetMetadataResponse: Decodable {
    let asset: String
    let metadata: Offchain? // off-chain registry data
    let onchain_metadata: Onchain? // on-chain CIP-25 data

    struct Offchain: Decodable {
        let name: String?
        let description: String?
        let image: String?
    }

    struct Onchain: Decodable {
        let name: String?
        let description: String?
        let image: String?
    }
}

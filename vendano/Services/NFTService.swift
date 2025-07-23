//
//  NFTService.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/23/25.
//

import Cardano
import CryptoKit
import Foundation
import SwiftUI

/// Centralizes NFT discovery and metadata parsing
actor NFTService {
    static let shared = NFTService()
    private let baseURL = Config.blockfrostAPIURL
    private let projectID = Config.blockfrostKey

    /// Helper to add the required header
    private func makeRequest(_ url: Foundation.URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.setValue(projectID, forHTTPHeaderField: "project_id")
        return try await WalletService.shared.getJSON(url)
    }

    /// 1. Fetch all UTxOs for the address, flatten into RawAssetEntry array
    func fetchRawAssets(address: String) async throws -> [RawAssetEntry] {
        let url = Foundation.URL(string: "\(baseURL)/addresses/\(address)/utxos")!
        let utxos = try JSONDecoder()
            .decode([UTXOResponse].self,
                    from: await makeRequest(url))
        // flatten every UTxO’s amount list into one big array
        return utxos.flatMap { $0.amount }
    }

    /// 2. Fetch the metadata for a single asset ID
    func fetchMetadata(for assetId: String) async throws -> AssetMetadataResponse {
        let url = Foundation.URL(string: "\(baseURL)/assets/\(assetId)")!
        return try JSONDecoder()
            .decode(AssetMetadataResponse.self,
                    from: await makeRequest(url))
    }

    /// 3. Combine and filter into [NFT]
    func fetchNFTs(address: String) async throws -> [NFT] {
        // only quantity == "1" & not lovelace
        let raws = try await fetchRawAssets(address: address)
            .filter { $0.quantity == "1" && $0.unit != "lovelace" }

        var results = [NFT]()
        for entry in raws {
            let metaResp = try await fetchMetadata(for: entry.unit)
            // prefer on-chain metadata if present
            let name = metaResp.onchain_metadata?.name
                ?? metaResp.metadata?.name
                ?? "Unknown"
            let desc = metaResp.onchain_metadata?.description
                ?? metaResp.metadata?.description
            // convert ipfs:// → https://ipfs.io/ipfs/
            let rawImg = metaResp.onchain_metadata?.image
                ?? metaResp.metadata?.image
            let imgURL: Foundation.URL? = {
                guard let raw = rawImg else { return nil }
                if raw.hasPrefix("ipfs://") {
                    return Foundation.URL(string:
                        raw.replacingOccurrences(of: "ipfs://",
                                                 with: "https://ipfs.io/ipfs/"))
                }
                return Foundation.URL(string: raw)
            }()

            results.append(.init(
                id: entry.unit,
                name: name,
                imageURL: imgURL,
                description: desc
            ))
        }
        return results
    }

    // Decoder helper for the /utxos endpoint
    private struct UTXOResponse: Decodable {
        let amount: [RawAssetEntry]
    }
}

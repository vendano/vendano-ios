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

actor NFTService {
    static let shared = NFTService()
    private let baseURL = Config.blockfrostAPIURL
    private let projectID = Config.blockfrostKey

    private func makeRequest(_ url: Foundation.URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.setValue(projectID, forHTTPHeaderField: "project_id")
        return try await WalletService.shared.getJSON(url)
    }

    func fetchRawAssets(address: String) async throws -> [RawAssetEntry] {
        let url = Foundation.URL(string: "\(baseURL)/addresses/\(address)/utxos")!
        let utxos = try JSONDecoder()
            .decode([UTXOResponse].self,
                    from: await makeRequest(url))
        return utxos.flatMap { $0.amount }
    }
    
    func fetchMetadata(for assetId: String) async throws
        -> (meta: AssetMetadataResponse, onchain: [String: Any]?) {
        let url = URL(string: "\(baseURL)/assets/\(assetId)")!
        let data = try await makeRequest(url)

        let meta = try JSONDecoder().decode(AssetMetadataResponse.self, from: data)

        let rawDict = try? (JSONSerialization.jsonObject(with: data) as? [String: Any])
        let onchain = rawDict?["onchain_metadata"] as? [String: Any]

        return (meta, onchain)
    }

    private func fetchRawAssets(stake: String) async throws -> [RawAssetEntry] {
        let url = URL(string:
            "\(baseURL)/accounts/\(stake)/addresses/assets?count=100")!
        struct Row: Decodable { let unit: String; let quantity: String }
        let rows = try JSONDecoder()
            .decode([Row].self, from: await makeRequest(url))
        return rows.map { RawAssetEntry(unit: $0.unit, quantity: $0.quantity) }
    }

    func fetchNFTs(address paymentAddr: String) async throws -> [NFT] {
        let stake = try? await WalletService.shared.stakeAddress(from: paymentAddr)
//        print("payment =", paymentAddr)
//        print("stake   =", stake ?? "<none>")

        let raws: [RawAssetEntry]
        if let s = stake {
            raws = try await fetchRawAssets(stake: s)
//            print("fetchRawAssets(stake) →", raws.count, "rows")
        } else {
            raws = try await fetchRawAssets(address: paymentAddr)
//            print("fetchRawAssets(addr) →", raws.count, "rows")
        }

        let nftUnits = raws.filter { $0.quantity == "1" && $0.unit != "lovelace" }
//        print("after NFT filter →", nftUnits.count, "candidates\n")
        guard !nftUnits.isEmpty else { return [] }

        var results: [NFT] = []

        for entry in nftUnits {
//            print("asset unit =", entry.unit)

            let (meta, oc) = try await fetchMetadata(for: entry.unit)

//            print("    onchain_metadata =", meta.onchain_metadata ?? "nil")
//            print("    registry metadata =", meta.metadata ?? "nil")
//            print("    raw on‑chain dict =", oc ?? "nil")

            let nft = buildNFT(entry: entry, meta: meta, oc: oc)
//            print("    → name        =", nft.name)
//            print("      description =", nft.description ?? "nil")
//            print("      traits      =", nft.traits ?? [:])
//            print()

            results.append(nft)
        }

//        print("returning", results.count, "NFTs total\n")
        return results
    }

    private struct UTXOResponse: Decodable {
        let amount: [RawAssetEntry]
    }

    private func extractImage(_ src: String) -> Foundation.URL? {
        if src.hasPrefix("ipfs://") {
            return URL(string: src.replacingOccurrences(of: "ipfs://", with: "https://ipfs.io/ipfs/"))
        }
        return URL(string: src)
    }

    private func lowercasedKeys(_ dict: [String: Any]) -> [String: Any] {
        Dictionary(uniqueKeysWithValues:
            dict.map { key, value in (key.lowercased(), value) })
    }

    // MARK: - Single asset -> NFT

    private func buildNFT(entry: RawAssetEntry, meta: AssetMetadataResponse, oc: [String: Any]?) -> NFT {
        let oc = oc.map(lowercasedKeys)

        let reserved: Set<String> = [
            "image", "name", "description",
            "project", "website", "twitter",
        ]

        let assetHex = String(entry.unit.dropFirst(56))
        let name = meta.onchain_metadata?.name
            ?? oc?["name"] as? String
            ?? assetHex.hexDecodedUTF8
            ?? assetHex

        let desc = oc?["description"] as? String
            ?? oc?["project"] as? String

        let imgStr = meta.onchain_metadata?.image
            ?? oc?["image"] as? String

        var traits = [String: String]()

        if let dict = oc {
            for (key, value) in dict where !reserved.contains(key) {
                if let str = value as? String, !str.isEmpty {
                    traits[key] = str
                }
            }
        }

        return NFT(
            id: entry.unit,
            name: name,
            imageURL: imgStr.flatMap(extractImage(_:)),
            description: desc,
            traits: traits.isEmpty ? nil : traits
        )
    }
}

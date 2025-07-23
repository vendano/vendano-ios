//
//  RawAsset.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/23/25.
//

import Foundation

/// Blockfrost raw asset entry
struct RawAssetEntry: Decodable {
    let unit: String // e.g. "lovelace" or "<policyHex><hexName>"
    let quantity: String // decimal string
}

//
//  NFT.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/23/25.
//

import Foundation

struct NFT: Identifiable {
    let id: String
    let name: String
    let imageURL: Foundation.URL?
    let description: String?
    let traits: [String: String]?
}

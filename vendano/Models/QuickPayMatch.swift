//  QuickPayMatch.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 1/5/26.
//

import Foundation

/// A lightweight "pairing checksum" so a payer can confirm they're connected to the right merchant.
/// We keep this Codable (no SwiftUI types) so it can travel over MultipeerConnectivity.
struct QuickPayMatch: Codable, Equatable {
    /// Index into a fixed color palette in the UI.
    let colorIndex: Int

    /// SF Symbol name (e.g. "sparkles", "bolt.fill")
    let symbolName: String

    static let paletteCount: Int = 6

    static let symbols: [String] = [
        "sparkles",
        "bolt.fill",
        "star.fill",
        "heart.fill",
        "flame.fill",
        "leaf.fill",
        "moon.stars.fill",
        "sun.max.fill",
        "cloud.fill",
        "paperplane.fill",
        "tag.fill",
        "cart.fill",
        "bag.fill",
        "gift.fill",
        "ticket.fill",
        "bell.fill",
        "camera.fill",
        "music.note",
        "gamecontroller.fill",
        "cup.and.saucer.fill",
        "fork.knife",
        "bicycle",
        "tram.fill",
        "airplane",
        "pawprint.fill",
        "globe.americas.fill",
        "wand.and.stars",
        "crown.fill",
        "diamond.fill",
        "shield.fill",
        "lock.fill",
        "key.fill",
        "bolt.circle.fill",
        "drop.fill",
        "snowflake",
        "tornado"
    ]

    static func random() -> QuickPayMatch {
        let c = Int.random(in: 0..<paletteCount)
        let s = symbols.randomElement() ?? "sparkles"
        return QuickPayMatch(colorIndex: c, symbolName: s)
    }
}

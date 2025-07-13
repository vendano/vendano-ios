//
//  BFCache.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/5/25.
//

import Foundation

// Very small “just enough” cache for Blockfrost JSON blobs.
actor BFCache {
    struct Entry { let data: Data; let fetchedAt: Date }
    private var store: [String: Entry] = [:]
    private let ttl: TimeInterval = 30 // seconds

    func get(_ key: String) -> Data? {
        if let e = store[key], Date().timeIntervalSince(e.fetchedAt) < ttl {
            return e.data
        }
        return nil
    }

    func set(_ key: String, data: Data) {
        store[key] = .init(data: data, fetchedAt: .now)
        // TODO: also write to FileManager / URLCache for persistence?
    }

    func reset() {
        store.removeAll(keepingCapacity: false)
    }
}

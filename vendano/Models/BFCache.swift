//
//  BFCache.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/5/25.
//

import Foundation

// Very small “just enough” cache for Blockfrost JSON blobs.
actor BFCache {
    struct Entry { let data: Data, etag: String?, fetchedAt: Date }
    private var store: [String: Entry] = [:]
    private let ttl: TimeInterval = 30
    
    /// Return the raw entry, even if it’s stale.
    func peek(_ key: String) -> Entry? {
        store[key]
    }
    
    /// Return only if fresh.
    func get(_ key: String) -> (Data, String?)? {
        guard let e = store[key],
              Date().timeIntervalSince(e.fetchedAt) < ttl
        else { return nil }
        return (e.data, e.etag)
    }
    
    func set(_ key: String, data: Data, etag: String?) {
        store[key] = .init(data: data, etag: etag, fetchedAt: .now)
    }
    
    func reset() { store.removeAll() }
}

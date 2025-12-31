//
//  String-extension.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/6/25.
//

import SwiftUI

extension String {
    func digit(at idx: Int) -> String {
        guard idx < count else { return "" }
        let i = index(startIndex, offsetBy: idx)
        return String(self[i])
    }

    func truncated(front: Int = 6, back: Int = 6) -> String {
        guard count > front + back + 3 else { return self }
        return prefix(front) + "…" + suffix(back)
    }

    var hexEncoded: String {
        data(using: .utf8)!
            .map { String(format: "%02x", $0) }
            .joined()
    }

    var hexDecodedUTF8: String? {
        var bytes = [UInt8](); bytes.reserveCapacity(count / 2)
        var idx = startIndex
        while idx < endIndex {
            let next = index(idx, offsetBy: 2)
            guard next <= endIndex,
                  let b = UInt8(self[idx ..< next], radix: 16) else { return nil }
            bytes.append(b)
            idx = next
        }
        return String(bytes: bytes, encoding: .utf8)
    }
    
    func replacingTokens(_ tokens: [String: String]) -> String {
        tokens.reduce(self) { result, pair in
            result.replacingOccurrences(of: "{{\(pair.key)}}", with: pair.value)
        }
    }
}

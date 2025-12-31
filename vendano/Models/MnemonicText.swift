//
//  MnemonicText.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 12/29/25.
//

import Foundation

enum MnemonicText {
    static func nfkd(_ s: String) -> String {
        s.decomposedStringWithCompatibilityMapping
    }

    static func tokenize(_ raw: String) -> [String] {
        // 1) NFKD
        let normalized = nfkd(raw)
            // 2) Treat Japanese ideographic spaces as whitespace too
            .replacingOccurrences(of: "\u{3000}", with: " ")
            // 3) Lowercasing is OK for latin-based lists; harmless for CJK
            .lowercased()

        // 4) Split on any whitespace/newlines
        let parts = normalized.split(whereSeparator: { $0.isWhitespace }).map(String.init)

        // 5) Trim surrounding punctuation users often paste with
        return parts.map {
            $0.trimmingCharacters(in: CharacterSet.punctuationCharacters.union(.symbols))
        }.filter { !$0.isEmpty }
    }
    
}

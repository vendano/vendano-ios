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
}

//
//  CardanoRustError-extension.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/5/25.
//

import CardanoCore
import Foundation

extension CardanoRustError: @retroactive LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .common(msg):
            return msg
        case let .deserialization(msg):
            return "Data error: \(msg)"
        case let .utf8(msg):
            return "Text encoding error: \(msg)"
        case let .panic(reason):
            return "Internal error: \(reason)"
        case .dataLengthMismatch:
            return "Unexpected data length."
        case .nullPtr:
            return "Internal null-pointer error."
        case .unknown:
            return "Unknown error."
        }
    }
}

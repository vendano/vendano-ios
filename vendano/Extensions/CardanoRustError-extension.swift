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
            return L10n.CardanoRustError.dataError(msg)
        case let .utf8(msg):
            return L10n.CardanoRustError.textEncodingError(msg)
        case let .panic(reason):
            return L10n.CardanoRustError.internalError(reason)
        case .dataLengthMismatch:
            return L10n.CardanoRustError.unexpectedDataLength
        case .nullPtr:
            return L10n.CardanoRustError.internalNullPointerError
        case .unknown:
            return L10n.CardanoRustError.unknownError
        }
    }
}

//
//  VendanoWalletMath.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 12/1/25.
//

import Foundation

struct VendanoWalletMath {
    static let lovelacePerAda: Double = 1_000_000
    static let minFeeOutputLovelace: UInt64 = 1_000_000   // 1 ADA

    static func adaToLovelace(_ ada: Double) -> UInt64 {
        guard ada > 0 else { return 0 }
        return UInt64(ada * lovelacePerAda)
    }

    static func lovelaceToAda(_ lovelace: UInt64) -> Double {
        Double(lovelace) / lovelacePerAda
    }

    /// Vendano fee in lovelace for a given *ADA* send amount.
    /// Waives the fee if it would be below the min-UTxO threshold.
    static func vendanoFeeLovelace(
        forSendAda ada: Double,
        percent: Double
    ) -> UInt64 {
        guard ada > 0, percent > 0 else { return 0 }

        let rawFeeAda = ada * percent
        let lovelace = adaToLovelace(rawFeeAda)

        return lovelace >= minFeeOutputLovelace ? lovelace : 0
    }

    /// Convenience overload: fee in lovelace when you already have lovelace.
    static func vendanoFeeLovelace(
        forSendLovelace lovelace: UInt64,
        percent: Double
    ) -> UInt64 {
        let ada = lovelaceToAda(lovelace)
        return vendanoFeeLovelace(forSendAda: ada, percent: percent)
    }

    /// Vendano fee in ADA, for display.
    static func vendanoFeeAda(
        forSendAda ada: Double,
        percent: Double
    ) -> Double {
        let lovelace = vendanoFeeLovelace(forSendAda: ada, percent: percent)
        return lovelaceToAda(lovelace)
    }
}

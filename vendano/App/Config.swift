//
//  Config.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/9/25.
//

import Foundation

enum Config {
    static var vendanoAppFeePercent: Double { 0.01 }
    static var vendanoAppFeePercentFormatted: String { "1%" }
    static var blockfrostAPIURL: String { "https://cardano-mainnet.blockfrost.io/api/v0" }

    static var vendanoFeeAddress: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "VENDANO_WALLET") as? String else {
            fatalError("VENDANO_WALLET not found in Info.plist")
        }
        return key
    }

    static var vendanoDeveloperAddress: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "DEV_WALLET") as? String else {
            fatalError("DEV_WALLET not found in Info.plist")
        }
        return key
    }

    static var blockfrostKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "BLOCKFROST_KEY") as? String else {
            fatalError("BLOCKFROST_KEY not found in Info.plist")
        }
        return key
    }
}

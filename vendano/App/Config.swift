//
//  Config.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/9/25.
//

import Foundation
import Cardano

enum Config {
    static var vendanoAppFeePercent: Double { 0.01 }
    static var vendanoAppFeePercentFormatted: String { "1%" }
    
    private static var env: AppEnvironment { AppState.shared.environment }
    
    static var cardanoInfo: NetworkApiInfo {
        switch env {
        case .mainnet:
            return .mainnet
        case .testnet, .demo:
            return .testnet
        }
    }
    
    static var blockfrostAPIURL: String {
        switch env {
        case .mainnet:
            return "https://cardano-mainnet.blockfrost.io/api/v0"
        case .testnet:
            return "https://cardano-preprod.blockfrost.io/api/v0"
        case .demo:
            return "https://cardano-preprod.blockfrost.io/api/v0"
        }
    }

    static var vendanoFeeAddress: String {
        let keyName = (env == .mainnet) ? "VENDANO_WALLET" : "VENDANO_WALLET_TESTNET"
        guard let key = Bundle.main.object(forInfoDictionaryKey: keyName) as? String else {
            fatalError("\(keyName) not found in Info.plist")
        }
        return key
    }

    static var vendanoDeveloperAddress: String {
        let keyName = (env == .mainnet) ? "DEV_WALLET" : "DEV_WALLET_TESTNET"
        guard let key = Bundle.main.object(forInfoDictionaryKey: keyName) as? String else {
            fatalError("\(keyName) not found in Info.plist")
        }
        return key
    }

    static var blockfrostKey: String {
        let keyName: String
        switch env {
        case .mainnet: keyName = "BLOCKFROST_KEY"
        case .testnet: keyName = "BLOCKFROST_KEY_TESTNET"
        case .demo:    keyName = "BLOCKFROST_KEY_TESTNET"
        }
        if let val = Bundle.main.object(forInfoDictionaryKey: keyName) as? String, !val.isEmpty {
            return val
        }
        // Fallback to the legacy key if testnet/demo keys aren’t present yet
        guard let fallback = Bundle.main.object(forInfoDictionaryKey: "BLOCKFROST_KEY") as? String else {
            fatalError("\(keyName) / BLOCKFROST_KEY not found in Info.plist")
        }
        return fallback
    }
    
    static var environmentName: String {
        switch env {
            case .mainnet: return "mainnet"
            case .testnet: return "testnet"
            case .demo:    return "demo"
        }
    }
    
}

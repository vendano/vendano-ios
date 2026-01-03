//  VendanoPaymentRequest.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 1/2/26.
//

import Foundation

struct VendanoPaymentRequest: Codable, Identifiable, Equatable {
    let id: String               // UUID string
    let createdAt: Date
    let expiresAt: Date

    // Display
    let storeName: String

    // Destination
    let merchantAddress: String

    // Pricing
    let pricingCurrency: PricingCurrency
    let fiatCurrencyCode: String?
    let fiatSubtotal: Double?            // what vendor typed (before buffer)
    let exchangeRateFiatPerAda: Double?  // e.g. 0.39 (USD per ADA)
    let bufferPercent: Double            // 0.0 ... 0.25

    // What payer actually pays (base, tip separate)
    let baseAda: Double

    // Tips
    let tipsEnabled: Bool

    var isExpired: Bool { Date() >= expiresAt }
}

struct VendanoPaymentResponse: Codable, Equatable {
    enum Status: String, Codable {
        case declined
        case accepted
        case paid
        case failed
        case expired
        case cancelled
    }

    let requestId: String
    let status: Status
    let txHash: String?
    let errorMessage: String?
}

//  PricingCurrency.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 1/2/26.
//

import Foundation

enum PricingCurrency: String, CaseIterable, Identifiable, Codable {
    case fiat
    case ada

    var id: String { rawValue }
}

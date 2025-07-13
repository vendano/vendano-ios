//
//  PriceService.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/16/25.
//

import Foundation

protocol PriceService {
    // Fetches the current price for a given trading pair, e.g. "ADA-USD".
    func fetchPrice(for pair: String) async throws -> Double
}

//
//  CoinbaseService.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/16/25.
//

import Foundation

// A service that fetches spot prices from Coinbase’s public API.
final class CoinbaseService: PriceService {
    private let session: URLSession
    private let baseURL = "https://api.coinbase.com/v2/prices"

    init(session: URLSession = .shared) {
        self.session = session
    }

    // Fetches the spot price for a given pair (e.g. "ADA-USD").
    func fetchPrice(for pair: String) async throws -> Double {
        let urlString = "\(baseURL)/\(pair)/spot"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct ResponseBody: Decodable {
            struct Data: Decodable {
                let amount: String
            }

            let data: Data
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        guard let price = Double(decoded.data.amount) else {
            throw URLError(.cannotParseResponse)
        }
        return price
    }
}

//
//  CoinGeckoService.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/16/25.
//

import Foundation

final class CoinGeckoService: PriceService {
    private let session: URLSession
    private let baseURL = "https://api.coingecko.com/api/v3/simple/price"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchPrice(for id: String) async throws -> Double {
        // Build URL: https://api.coingecko.com/api/v3/simple/price?ids=hosky&vs_currencies=usd
        var comps = URLComponents(string: baseURL)
        comps?.queryItems = [
            URLQueryItem(name: "ids", value: id),
            URLQueryItem(name: "vs_currencies", value: "usd")
        ]
        guard let url = comps?.url else {
            throw URLError(.badURL)
        }

        let (data, resp) = try await session.data(from: url)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Decode shape: { "hosky": { "usd": 0.00000004 } }
        struct Inner: Decodable { let usd: Double }
        let mapping = try JSONDecoder().decode([String: Inner].self, from: data)

        guard let price = mapping[id]?.usd else {
            throw URLError(.cannotParseResponse)
        }
        return price
    }
}

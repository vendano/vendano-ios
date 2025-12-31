//
//  FAQDocument.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 12/29/25.
//


import Foundation

struct FAQDocument: Decodable {
    let version: Int
    let sections: [FAQSection]
}

struct FAQSection: Decodable, Identifiable {
    let id: String
    let title: String
    let items: [FAQItem]
}

struct FAQItem: Decodable, Identifiable, Equatable {
    let id: String
    let icon: String
    let question: String
    let tldr: String
    let answer: String
    let clarify: String
    let details: String
}

enum FAQLoader {
    static func load(name: String = "FAQs") throws -> FAQDocument {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw NSError(domain: "FAQLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: L10n.FAQLoader.missingJSONInBundle(name: name)])
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(FAQDocument.self, from: data)
    }
}

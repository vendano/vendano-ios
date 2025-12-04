//
//  FiatCurrency.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 12/1/25.
//


enum FiatCurrency: String, CaseIterable, Identifiable {
    case usd = "USD"   // United States
    case eur = "EUR"   // Euro
    case gbp = "GBP"   // Great Britain
    case jpy = "JPY"   // Japan
    case mxn = "MXN"   // Mexico
    case krw = "KRW"   // South Korea
    case php = "PHP"   // Philippines
    case inr = "INR"   // India

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        case .jpy: return "¥"
        case .mxn: return "$"
        case .krw: return "₩"
        case .php: return "₱"
        case .inr: return "₹"
        }
    }

    var displayName: String {
        switch self {
        case .usd: return "US Dollar (USD)"
        case .eur: return "Euro (EUR)"
        case .gbp: return "British Pound (GBP)"
        case .jpy: return "Japanese Yen (JPY)"
        case .mxn: return "Mexican Peso (MXN)"
        case .krw: return "South Korean Won (KRW)"
        case .php: return "Philippine Peso (PHP)"
        case .inr: return "Indian Rupee (INR)"
        }
    }

    /// String passed to your PriceService, e.g. "ADA-USD"
    var pricePair: String { "ADA-\(rawValue)" }
}

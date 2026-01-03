//
//  FiatCurrency.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 12/1/25.
//

enum FiatCurrency: String, CaseIterable, Identifiable {
    case usd = "USD" // United States
    case eur = "EUR" // Euro
    case gbp = "GBP" // Great Britain
    case jpy = "JPY" // Japan
    case mxn = "MXN" // Mexico
    case krw = "KRW" // South Korea
    case php = "PHP" // Philippines
    case inr = "INR" // India

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
        case .usd: return L10n.FiatCurrency.usd
        case .eur: return L10n.FiatCurrency.eur
        case .gbp: return L10n.FiatCurrency.gbp
        case .jpy: return L10n.FiatCurrency.jpy
        case .mxn: return L10n.FiatCurrency.mxn
        case .krw: return L10n.FiatCurrency.krw
        case .php: return L10n.FiatCurrency.php
        case .inr: return L10n.FiatCurrency.inr
        }
    }

    /// String passed to your PriceService, e.g. "ADA-USD"
    var pricePair: String { "ADA-\(rawValue)" }
}

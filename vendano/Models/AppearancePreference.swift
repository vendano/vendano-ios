//
//  AppearancePreference.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/23/25.
//

import Foundation

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .system: return "Default"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

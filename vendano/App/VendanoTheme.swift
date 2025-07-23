//
//  VendanoTheme.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/13/25.
//

import SwiftUI

@MainActor
class VendanoTheme: ObservableObject {
    static let shared = VendanoTheme()

    func isHosky() -> Bool {
        return currentPalette == .hosky
    }

    enum Palette {
        case light, dark, hosky
    }

    enum TextStyle {
        case body // most normal text
        case headline // medium‐large headings
        case title // such as the ADA amount on the home view
        case caption // small footnotes, etc.
    }

    @Published var currentPalette: Palette = .light

    func color(named key: String) -> Color {
        switch currentPalette {
        case .light:
            return lightColors[key] ?? Color(key)
        case .dark:
            return darkColors[key] ?? Color(key)
        case .hosky:
            return hoskyColors[key] ?? Color(key)
        }
    }

    // your existing dictionaries…
    private var lightColors: [String: Color] = [
        "Accent": Color("Accent"),
        "BackgroundEnd": Color("BackgroundEnd"),
        "BackgroundLaunch": Color("BackgroundLaunch"),
        "BackgroundStart": Color("BackgroundStart"),
        "CellBackground": Color("CellBackground"),
        "FieldBackground": Color("FieldBackground"),
        "Negative": Color("Negative"),
        "Positive": Color("Positive"),
        "TextPrimary": Color("TextPrimary"),
        "TextReversed": Color("TextReversed"),
        "TextSecondary": Color("TextSecondary"),
        "AccentAlt": Color("AccentAlt"),
        "GlowPurple": Color("GlowPurple"),
        "GlowPink": Color("GlowPink"),
    ]
    private var darkColors: [String: Color] = [
        "Accent": Color("Accent"),
        "BackgroundEnd": Color("BackgroundEnd"),
        "BackgroundLaunch": Color("BackgroundLaunch"),
        "BackgroundStart": Color("BackgroundStart"),
        "CellBackground": Color("CellBackground"),
        "FieldBackground": Color("FieldBackground"),
        "Negative": Color("Negative"),
        "Positive": Color("Positive"),
        "TextPrimary": Color("TextPrimary"),
        "TextReversed": Color("TextReversed"),
        "TextSecondary": Color("TextSecondary"),
        "AccentAlt": Color("AccentAlt"),
        "GlowPurple": Color("GlowPurple"),
        "GlowPink": Color("GlowPink"),
    ]
    private var hoskyColors: [String: Color] = [
        "Accent": Color("HoskyAccent"),
        "BackgroundEnd": Color("HoskyBackgroundEnd"),
        "BackgroundLaunch": Color("HoskyBackgroundLaunch"),
        "BackgroundStart": Color("HoskyBackgroundStart"),
        "CellBackground": Color("HoskyCellBackground"),
        "FieldBackground": Color("HoskyFieldBackground"),
        "Negative": Color("HoskyNegative"),
        "Positive": Color("HoskyPositive"),
        "TextPrimary": Color("HoskyTextPrimary"),
        "TextReversed": Color("HoskyTextReversed"),
        "TextSecondary": Color("HoskyTextSecondary"),
        "AccentAlt": Color("HoskyAccentAlt"),
        "GlowPurple": Color("HoskyGlowPurple"),
        "GlowPink": Color("HoskyGlowPink"),
    ]

    func font(_ style: TextStyle, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // In .hosky mode we swap in the custom fonts
        if currentPalette == .hosky {
            switch style {
            case .body, .caption:
                // use Minecraft for most text
                return .custom("Minecraft", size: size)

            case .headline:
                return .custom("Pixeled", size: size)

            case .title:
                // use Minercraftery for large title‐style amounts
                return .custom("MinercraftoryRegular", size: size)
            }
        }

        // Otherwise fall back to the system font
        switch style {
        case .body:
            return .system(size: size, weight: weight)
        case .headline:
            return .system(size: size, weight: .semibold)
        case .title:
            return .system(size: size, weight: .bold)
        case .caption:
            return .system(size: size * 0.8, weight: .regular)
        }
    }
}

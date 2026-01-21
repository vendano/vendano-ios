//  QuickPayMatchBadge.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 1/5/26.
//

import SwiftUI

struct QuickPayMatchBadge: View {
    @EnvironmentObject var theme: VendanoTheme
    let match: QuickPayMatch
    var size: CGFloat = 84

    private var palette: [Color] {
        [
            Color(uiColor: .systemTeal),
            Color(uiColor: .systemBlue),
            Color(uiColor: .systemIndigo),
            Color(uiColor: .systemPurple),
            Color(uiColor: .systemPink),
            Color(uiColor: .systemMint)
        ]
    }

    private var fill: Color {
        let idx = max(0, min(match.colorIndex, palette.count - 1))
        return palette[idx]
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(fill)
                .overlay(
                    Circle().stroke(theme.color(named: "TextReversed").opacity(0.9), lineWidth: max(2, size * 0.06))
                )
                .shadow(radius: 6)

            Image(systemName: match.symbolName)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(theme.color(named: "TextReversed"))
                .shadow(radius: 1)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Quick Pay match")
    }
}

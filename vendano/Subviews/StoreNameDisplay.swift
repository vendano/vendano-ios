//
//  StoreNameDisplay.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 1/5/26.
//

import SwiftUI

struct StoreNameDisplay: View {
    @EnvironmentObject var theme: VendanoTheme
    let name: String

    private let fontSize: CGFloat = 34
    private let outline: CGFloat = 2

    var body: some View {
        ZStack {
            // Fill
            Text(name)
                .font(.system(size: fontSize, weight: .heavy))
                .foregroundStyle(theme.color(named: "TextReversed"))
                .kerning(0.5)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .shadow(color: theme.color(named: "TextPrimary").opacity(0.80), radius: 4, x: 0, y: 3)
        }
        .accessibilityLabel(Text(name))
    }
}

#Preview {
    ZStack {
        Rectangle()
            .foregroundStyle(.orange)
        
        StoreNameDisplay(name: "Example Store")
            .environmentObject(VendanoTheme.shared)
    }
}

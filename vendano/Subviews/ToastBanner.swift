//
//  ToastBanner.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 8/30/25.
//

import SwiftUI

struct ToastBanner: View {
    @EnvironmentObject var theme: VendanoTheme
    let text: String
    var icon: String? = "checkmark.circle.fill"

    var body: some View {
        HStack(spacing: 8) {
            if let icon { Image(systemName: icon).imageScale(.medium) }
            Text(text)
                .vendanoFont(.body, size: 15, weight: .semibold)
                .lineLimit(2)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(theme.color(named: "Accent"))
        .foregroundColor(theme.color(named: "TextReversed"))
        .clipShape(Capsule())
        .shadow(radius: 10, y: 4)
        .padding(.horizontal)
        .allowsHitTesting(false)
    }
}

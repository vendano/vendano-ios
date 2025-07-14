//
//  CapsuleButtonStyle.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/20/25.
//

import SwiftUI

struct CapsuleButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: VendanoTheme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .vendanoFont(.body, size: 16, weight: .semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                Group {
                    if isEnabled {
                        theme.color(named: "TextReversed")
                    } else {
                        theme.color(named: "TextReversed").opacity(0.4)
                    }
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(theme.color(named: "Accent"), lineWidth: 2)
            )
            .shadow(color: theme.color(named: "Accent").opacity(0.4),
                    radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            // ensures the full capsule is tappable
            .contentShape(Capsule())
    }
}

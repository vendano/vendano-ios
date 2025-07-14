//
//  PrimaryButtonStyle.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/17/25.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @EnvironmentObject var theme: VendanoTheme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .vendanoFont(.body, size: 18, weight: .semibold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isEnabled {
                        theme.color(named: "Accent")
                    } else {
                        theme.color(named: "Accent").opacity(0.4)
                    }
                }
            )
            .foregroundColor(
                theme.color(named: "TextReversed")
                    .opacity(isEnabled ? 1 : 0.7)
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

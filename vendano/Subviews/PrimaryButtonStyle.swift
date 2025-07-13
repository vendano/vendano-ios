//
//  PrimaryButtonStyle.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/17/25.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isEnabled {
                        Color("Accent")
                    } else {
                        Color("Accent").opacity(0.4)
                    }
                }
            )
            .foregroundColor(
                Color("TextReversed")
                    .opacity(isEnabled ? 1 : 0.7)
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

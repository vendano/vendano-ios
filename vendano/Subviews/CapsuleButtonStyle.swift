//
//  CapsuleButtonStyle.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/20/25.
//

import SwiftUI

struct CapsuleButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                Group {
                    if isEnabled {
                        Color("TextReversed")
                    } else {
                        Color("TextReversed").opacity(0.4)
                    }
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color("Accent"), lineWidth: 2)
            )
            .shadow(color: Color("Accent").opacity(0.4),
                    radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            // ensures the full capsule is tappable
            .contentShape(Capsule())
    }
}

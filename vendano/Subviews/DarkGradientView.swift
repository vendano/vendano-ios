//
//  DarkGradientView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/18/25.
//

import SwiftUI

struct DarkGradientView: View {
    @EnvironmentObject var theme: VendanoTheme
    var body: some View {
        ZStack {
            theme.color(named: "BackgroundStart")
                .edgesIgnoringSafeArea(.all)

            LinearGradient(
                gradient: Gradient(colors: [
                    theme.color(named: "Accent").opacity(0.9),
                    theme.color(named: "Accent").opacity(0.7),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if VendanoTheme.shared.isHosky() {
                RadialGradient(
                    gradient: Gradient(colors: [
                        theme.color(named: "GlowPink").opacity(0.6),
                        theme.color(named: "GlowPurple").opacity(0.4),
                        .clear,
                    ]),
                    center: .center,
                    startRadius: 80,
                    endRadius: 500
                )
                .blendMode(.screen)
                .ignoresSafeArea()

                AngularGradient(
                    gradient: Gradient(colors: [
                        theme.color(named: "GlowPurple"),
                        theme.color(named: "GlowPink"),
                        theme.color(named: "AccentAlt"),
                        theme.color(named: "GlowPurple"),
                    ]),
                    center: .center
                )
                .opacity(0.5)
                .blendMode(.overlay)
                .rotationEffect(.degrees(45))
                .ignoresSafeArea()
            }
        }
    }
}

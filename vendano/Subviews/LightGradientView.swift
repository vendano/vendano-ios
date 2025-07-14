//
//  LightGradientView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/16/25.
//

import SwiftUI

struct LightGradientView: View {
    @EnvironmentObject var theme: VendanoTheme
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    theme.color(named: "BackgroundStart"),
                    theme.color(named: "BackgroundEnd")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if VendanoTheme.shared.isHosky() {
                
                RadialGradient(
                    gradient: Gradient(colors: [
                        theme.color(named: "GlowPink").opacity(0.35),
                        theme.color(named: "GlowPurple").opacity(0.25),
                        Color.white.opacity(0.05),
                        .clear
                    ]),
                    center: .center,
                    startRadius: 60,
                    endRadius: 450
                )
                .blendMode(.softLight)
                .ignoresSafeArea()

                AngularGradient(
                    gradient: Gradient(colors: [
                        theme.color(named: "GlowPink"),
                        theme.color(named: "GlowPurple"),
                        theme.color(named: "AccentAlt"),
                        theme.color(named: "GlowPink")
                    ]),
                    center: .center
                )
                .opacity(0.4)
                .blendMode(.overlay)
                .rotationEffect(.degrees(-20))
                .ignoresSafeArea()
                
            }
            
            
        }
    }
}

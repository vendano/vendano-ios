//
//  BlurView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/7/25.
//

import SwiftUI

struct BlurView: View {
    @EnvironmentObject var theme: VendanoTheme
    var body: some View {
        ZStack {
            DarkGradientView()

            VStack(spacing: 24) {
                Image(VendanoTheme.shared.isHosky() ? "vendoggo-logo" : "vendano-logo")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(theme.color(named: "TextReversed"))
                    .scaledToFit()
                    .frame(width: 120)
                    .padding()

                Text(VendanoTheme.shared.isHosky() ? "vendoggo" : "vendano")
                    .vendanoFont(.title, size: 48, weight: .heavy)
                    .foregroundColor(theme.color(named: "TextReversed"))
            }
            .padding()
        }
    }
}

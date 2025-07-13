//
//  DarkGradientView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/18/25.
//

import SwiftUI

struct DarkGradientView: View {
    var body: some View {
        ZStack {
            Color.white.opacity(1.0)
                .edgesIgnoringSafeArea(.all)

            LinearGradient(
                gradient: Gradient(colors: [
                    Color("Accent").opacity(0.9),
                    Color("Accent").opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

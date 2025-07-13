//
//  LightGradientView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/16/25.
//

import SwiftUI

struct LightGradientView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("BackgroundStart"),
                Color("BackgroundEnd")
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

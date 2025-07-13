//
//  BlurView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/7/25.
//

import SwiftUI

struct BlurView: View {
    var body: some View {
        ZStack {
            DarkGradientView()

            VStack(spacing: 24) {
                Image("vendano-logo")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color("TextReversed"))
                    .scaledToFit()
                    .frame(width: 120)
                    .padding()

                Text("vendano")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundColor(Color("TextReversed"))
            }
            .padding()
        }
    }
}

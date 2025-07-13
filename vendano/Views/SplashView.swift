//
//  SplashView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import SwiftUI

struct SplashView: View {
    @StateObject private var state = AppState.shared
    @State private var pulse = false

    var loading: Bool

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
                    .scaleEffect(pulse ? 1.6 : 0.8)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                            pulse.toggle()
                        }
                    }

                Text("Vendano")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundColor(Color("TextPrimary"))

                Text("Easy ADA transfers\nby phone or email.")
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("TextPrimary").opacity(0.85))

                Spacer()
                    .frame(height: 48)

                if loading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color("TextReversed"))
                } else {
                    Button("Get started") {
                        state.onboardingStep = .faq
                    }
                    .buttonStyle(.plain)
                    .padding()
                    .background(Color("TextReversed"))
                    .clipShape(Capsule())
                    .shadow(color: Color("Accent").opacity(0.4), radius: 8, x: 0, y: 4)
                    .overlay(
                        Capsule()
                            .stroke(Color("Accent"), lineWidth: 2)
                    )
                }
            }
            .padding()
        }
    }
}

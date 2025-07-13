//
//  OfflineBanner.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/21/25.
//

import SwiftUI

struct OfflineBanner: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

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
                        withAnimation(
                            .easeInOut(duration: 1)
                                .repeatForever(autoreverses: true)
                        ) {
                            pulse.toggle()
                        }
                    }

                Text("Vendano")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundColor(Color("TextPrimary"))

                Text("No internet connection.\nPlease check your network and try again.")
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color("TextPrimary").opacity(0.85))

                Spacer().frame(height: 48)

//                Button("Retry") {
//                    // Force a re-check by restarting the monitor:
//                    // (could also attempt a manual reload)
//                    let _ = NetworkMonitor()
//                }
//                .buttonStyle(.plain)
//                .padding()
//                .background(Color("TextReversed"))
//                .clipShape(Capsule())
//                .shadow(color: Color("Accent").opacity(0.4),
//                        radius: 8, x: 0, y: 4)
//                .overlay(
//                    Capsule().stroke(Color("Accent"), lineWidth: 2)
//                )
            }
            .padding()
        }
    }
}

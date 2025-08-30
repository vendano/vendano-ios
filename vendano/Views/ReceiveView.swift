//
//  ReceiveView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct ReceiveView: View {
    @EnvironmentObject var theme: VendanoTheme
    @Environment(\.openURL) private var openURL

    @StateObject private var state = AppState.shared
    @StateObject private var wallet = WalletService.shared
    
    let onClose: () -> Void

    @State private var qrImage: UIImage? = nil

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        ZStack {
            DarkGradientView().ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.color(named: "TextReversed").opacity(0.7))
                    }
                }

                ScrollView {
                    VStack(spacing: 8) {
                        
                        HStack(spacing: 8) {
                            Text("Receive ADA")
                                .vendanoFont(.title, size: 24, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextReversed"))
                            
                            Text("Cardano • Mainnet")
                                .vendanoFont(.caption, size: 12, weight: .semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(theme.color(named: "FieldBackground"))
                                .cornerRadius(999)
                                .foregroundColor(theme.color(named: "TextPrimary"))
                                .accessibilityHidden(true)
                        }
                        
                        Text("Scan with any Cardano wallet or exchange app to receive ADA for this account.")
                            .vendanoFont(.body, size: 16)
                            .foregroundColor(theme.color(named: "TextReversed").opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 24) {
                        // QR section
                        VStack(spacing: 8) {
                            Text("Your Cardano address (for ADA)")
                                .vendanoFont(.body, size: 16, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextPrimary"))
                            
                            if let qr = qrImage {
                                Image(uiImage: qr)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                                    .padding(12)
                                    .background(theme.color(named: "CellBackground"))
                                    .accessibilityLabel("QR for your Cardano address")
                            } else {
                                ProgressView()
                                    .frame(width: 200, height: 200)
                                    .padding(12)
                                    .background(theme.color(named: "CellBackground"))
                            }
                        }
                        .onAppear {
                            DispatchQueue.global(qos: .userInitiated).async {
                                let generated = generateQRCode()
                                DispatchQueue.main.async {
                                    qrImage = generated
                                }
                            }
                        }
                        
                        // Address box
                        Text(state.walletAddress)
                            .monospaced()
                            .vendanoFont(.caption, size: 13)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(theme.color(named: "FieldBackground"))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                        
                        // Actions
                        HStack(spacing: 16) {
                            Button {
                                AnalyticsManager.logEvent("receive_copy_walletaddress")
                                UIPasteboard.general.string = state.walletAddress
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                AppState.shared.showToast("Wallet address copied")
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            
                            Button {
                                AnalyticsManager.logEvent("receive_share_walletaddress")
                                let sheet = UIActivityViewController(
                                    activityItems: [state.walletAddress],
                                    applicationActivities: nil
                                )
                                let allScenes = UIApplication.shared.connectedScenes
                                let scene = allScenes.first { $0.activationState == .foregroundActive }
                                
                                if let windowScene = scene as? UIWindowScene {
                                    windowScene.keyWindow?.rootViewController?.present(sheet, animated: true, completion: nil)
                                }
                                
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        
                        if wallet.adaBalance == 0 {
                            DisclosureGroup(
                                content: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("1. Create an account at a trusted exchange (for example: Coinbase or Kraken).")
                                        Text("2. Buy ADA with your bank or card.")
                                        Text("3. In the exchange, choose **Send** or **Withdraw**, paste the address above, and confirm.")
                                        Text("Optional: Start with a small test amount if you’d like.")
                                            .foregroundColor(theme.color(named: "TextSecondary"))
                                        
                                        Button("Step-by-step guide →") {
                                            guard let url = URL(string: "https://vendano.net/getting-ada.html") else { return }
                                            openURL(url)
                                        }
                                        .vendanoFont(.body, size: 16)
                                        .padding()
                                        .foregroundColor(theme.color(named: "TextReversed"))
                                        .background(theme.color(named: "Accent"))
                                        .cornerRadius(6)
                                    }
                                    .vendanoFont(.caption, size: 14)
                                    .padding(.top, 8)
                                },
                                label: {
                                    Text("New here? Add ADA in three easy steps")
                                        .vendanoFont(.headline, size: 18, weight: .semibold)
                                        .multilineTextAlignment(.leading)
                                }
                            )
                            .accentColor(theme.color(named: "Accent"))
                            .padding()
                            .background(theme.color(named: "CellBackground"))
                            .cornerRadius(12)
                            
                            SafetyTipCard(color: theme.color(named: "FieldBackground"))
                                .vendanoFont(.caption, size: 14)
                                .foregroundColor(theme.color(named: "TextPrimary"))
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .padding()
            }
            .padding()
        }
        .overlay(alignment: .top) {
            if state.displayToast {
                ToastBanner(text: state.toastMessage)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(9999)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: state.displayToast)
    }
    
    private struct SafetyTipCard: View {
        let color: Color
        var body: some View {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .imageScale(.medium)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Safety tip")
                        .font(.system(size: 15, weight: .semibold))

                    // Calm, non-alarmist copy
                    Text("Keep your recovery phrase (12–24 words) written down in a safe place. You only use it to restore your wallet in a wallet app. No one - including Vendano support or exchanges - will ask for it in chat or email.")
                        .font(.system(size: 13))
                }
            }
            .padding(12)
            .background(color.opacity(0.6))  // neutral, not “error” red
            .cornerRadius(10)
        }
    }

    // MARK: – QR generator

    func generateQRCode() -> UIImage {
        // Encode the raw Cardano address for maximum compatibility
        let payload = state.walletAddress

        filter.message = Data(payload.utf8)
        filter.setValue("L", forKey: "inputCorrectionLevel")

        let qrTransform = CGAffineTransform(scaleX: 12, y: 12)
        if let outputImage = filter.outputImage?.transformed(by: qrTransform),
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return UIImage(systemName: "qrcode") ?? UIImage()
    }

}

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
    @StateObject private var state = AppState.shared
    let onClose: () -> Void

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
                            .foregroundColor(Color("TextReversed").opacity(0.7))
                    }
                }

                VStack(spacing: 8) {
                    Text("Receive ADA")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color("TextReversed"))
                    Text("Scan this QR in your Vendano app to send ADA to you")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("TextReversed").opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 24) {
                    // QR section
                    VStack(spacing: 8) {
                        Text("Your receive code")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("TextPrimary"))
                        Image(uiImage: generateQRCode())
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding(12)
                            .background(Color("CellBackground"))
                    }

                    // Address box
                    Text(state.walletAddress)
                        .font(.system(.footnote, design: .monospaced))
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color("FieldBackground"))
                        .cornerRadius(8)
                        .textSelection(.enabled)

                    // Actions
                    HStack(spacing: 16) {
                        Button {
                            UIPasteboard.general.string = state.walletAddress
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button {
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
                }
                .padding()

                Spacer()
            }
            .padding()
        }
    }

    // MARK: – QR generator

    func generateQRCode() -> UIImage {
        let link = "https://vendano.net/receive?addr=\(state.walletAddress)"

        filter.message = Data(link.utf8)
        filter.setValue("L", forKey: "inputCorrectionLevel")

        let qrTransform = CGAffineTransform(scaleX: 12, y: 12)

        if let outputImage = filter.outputImage?.transformed(by: qrTransform) {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }

        return UIImage(systemName: "qrcode") ?? UIImage()
    }
}

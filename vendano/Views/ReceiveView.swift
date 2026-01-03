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
    @AppStorage("receive.mode") private var receiveModeStored: String = ReceiveMode.personal.rawValue

    @StateObject private var state = AppState.shared
    @StateObject private var wallet = WalletService.shared

    let onClose: () -> Void

    @State private var qrImage: UIImage? = nil

    @State private var isShowingShareSheet = false

    enum ReceiveMode: String, CaseIterable, Identifiable {
        case personal
        case store
        var id: String { rawValue }
    }

    @State private var receiveMode: ReceiveMode = .personal

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

                Picker("", selection: $receiveMode) {
                    Text(L10n.StoreView.personalTab).tag(ReceiveMode.personal)
                    Text(L10n.StoreView.storeTab).tag(ReceiveMode.store)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ScrollView {
                    if receiveMode == .personal {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Text(L10n.ReceiveView.receiveAda)
                                    .vendanoFont(.title, size: 24, weight: .semibold)
                                    .foregroundColor(theme.color(named: "TextReversed"))

                                Text(L10n.ReceiveView.cardanoMainnet)
                                    .vendanoFont(.caption, size: 12, weight: .semibold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(theme.color(named: "FieldBackground"))
                                    .cornerRadius(999)
                                    .foregroundColor(theme.color(named: "TextPrimary"))
                                    .accessibilityHidden(true)
                            }

                            Text(L10n.ReceiveView.scanWithAnyCardanoWalletOrExchangeApp)
                                .vendanoFont(.body, size: 16)
                                .foregroundColor(theme.color(named: "TextReversed").opacity(0.8))
                                .multilineTextAlignment(.center)
                        }

                        VStack(spacing: 24) {
                            // QR section
                            VStack(spacing: 8) {
                                Text(L10n.ReceiveView.yourCardanoAddressForAda)
                                    .vendanoFont(.body, size: 16, weight: .semibold)
                                    .foregroundColor(theme.color(named: "TextPrimary"))

                                if let qr = qrImage {
                                    Image(uiImage: qr)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 200, height: 200)
                                        .padding(12)
                                        .background(theme.color(named: "CellBackground"))
                                        .accessibilityLabel(L10n.ReceiveView.qrAccessibilityLabel)
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
                                    AppState.shared.showToast(L10n.ReceiveView.walletAddressCopiedToast)
                                } label: {
                                    Label(L10n.ReceiveView.copy, systemImage: "doc.on.doc")
                                }
                                .buttonStyle(PrimaryButtonStyle())

                                Button {
                                    AnalyticsManager.logEvent("receive_share_walletaddress")
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    isShowingShareSheet = true
                                } label: {
                                    Label(L10n.ReceiveView.share, systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }

                            if wallet.adaBalance == 0 {
                                DisclosureGroup(
                                    content: {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(L10n.ReceiveView.text1CreateAnAccountAtATrustedExchange)
                                            Text(L10n.ReceiveView.text2BuyAdaWithYourBankOrCard)
                                            Text(L10n.ReceiveView.text3InTheExchangeChooseSendOrWithdraw)
                                            Text(L10n.ReceiveView.optionalStartWithASmallTestAmountIf)
                                                .foregroundColor(theme.color(named: "TextSecondary"))

                                            Button(L10n.ReceiveView.stepByStepGuide) {
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
                                        Text(L10n.ReceiveView.newHereAddAdaInThreeEasySteps)
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

                    } else {
                        ReceiveStoreView()
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .padding()
        }
        .onAppear {
            // initialize state from storage
            let stored = ReceiveMode(rawValue: receiveModeStored) ?? .personal
            if stored == .store,
               state.storeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                receiveMode = .personal
            } else {
                receiveMode = stored
            }
        }
        .onChange(of: receiveMode) { _, newValue in
            receiveModeStored = newValue.rawValue
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
        .sheet(isPresented: $isShowingShareSheet) {
            ShareActivityView(activityItems: [state.walletAddress])
                .environmentObject(theme)
        }
    }

    private struct SafetyTipCard: View {
        let color: Color
        var body: some View {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .imageScale(.medium)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.ReceiveView.safetyTip)
                        .font(.system(size: 15, weight: .semibold))

                    // Calm, non-alarmist copy
                    Text(L10n.ReceiveView.keepYourRecoveryPhrase1224WordsWritten)
                        .font(.system(size: 13))
                }
            }
            .padding(12)
            .background(color.opacity(0.6)) // neutral, not “error” red
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
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        {
            return UIImage(cgImage: cgImage)
        }
        return UIImage(systemName: "qrcode") ?? UIImage()
    }
}

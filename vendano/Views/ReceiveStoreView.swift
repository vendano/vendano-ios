//  ReceiveStoreView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 1/2/26.
//

import SwiftUI

struct ReceiveStoreView: View {
    @EnvironmentObject var theme: VendanoTheme

    @StateObject private var state = AppState.shared
    @StateObject private var wallet = WalletService.shared

    @State private var pricingCurrency: PricingCurrency = .fiat
    @State private var amountText: String = ""

    @State private var showTapToCollect = false

    private var numberFormatter: NumberFormatter {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale.current
        nf.maximumFractionDigits = 2
        return nf
    }

    private var enteredAmount: Double {
        numberFormatter.number(from: amountText)?.doubleValue ?? 0
    }

    private var baseAda: Double? {
        switch pricingCurrency {
        case .ada:
            return enteredAmount > 0 ? enteredAmount : nil
        case .fiat:
            guard enteredAmount > 0, let rate = wallet.adaFiatRate, rate > 0 else { return nil }
            let bufferedFiat = enteredAmount * (1.0 + state.storeExchangeRateBufferPercent)
            return bufferedFiat / rate
        }
    }

    private var canCollect: Bool {
        baseAda != nil && !(state.storeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) && !state.walletAddress.isEmpty
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(state.storeName.isEmpty ? L10n.StoreView.storeNameNotSet : state.storeName)
                    .vendanoFont(.headline, size: 22, weight: .bold)
                    .foregroundColor(theme.color(named: "TextPrimary"))

                Text(L10n.StoreView.acceptPaymentsSubtitle)
                    .vendanoFont(.body, size: 14)
                    .foregroundColor(theme.color(named: "TextSecondary"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TextField(L10n.StoreView.amountPlaceholder, text: $amountText)
                        .keyboardType(.decimalPad)
                        .vendanoFont(.title, size: 34, weight: .bold)
                        .foregroundColor(theme.color(named: "TextPrimary"))
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Picker("", selection: $pricingCurrency) {
                        Text(wallet.fiatCurrency.rawValue).tag(PricingCurrency.fiat)
                        Text("ADA").tag(PricingCurrency.ada)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                .padding(12)
                .background(theme.color(named: "CellBackground"))
                .cornerRadius(14)

                VStack(alignment: .leading, spacing: 6) {
                    if pricingCurrency == .fiat {
                        if let rate = wallet.adaFiatRate, rate > 0, let ada = baseAda {
                            let bufferedFiat = enteredAmount * (1.0 + state.storeExchangeRateBufferPercent)
                            Text(L10n.StoreView.convertsToAda)
                                .vendanoFont(.caption, size: 13, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextSecondary"))

                            Text("\(ada.formatted(.number.precision(.fractionLength(3...6)))) ADA")
                                .vendanoFont(.headline, size: 20, weight: .bold)
                                .foregroundColor(theme.color(named: "TextPrimary"))

                            Text(L10n.StoreView.rateAndBuffer(wallet.fiatCurrency.rawValue, rate, Int((state.storeExchangeRateBufferPercent * 100).rounded()), bufferedFiat))
                                .vendanoFont(.caption, size: 13)
                                .foregroundColor(theme.color(named: "TextSecondary"))
                        } else {
                            Text(L10n.StoreView.fetchingRate(wallet.fiatCurrency.rawValue))
                                .vendanoFont(.caption, size: 13)
                                .foregroundColor(theme.color(named: "TextSecondary"))

                            Button(L10n.StoreView.refreshRate) {
                                Task { await wallet.loadPrice() }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    } else {
                        if let ada = baseAda {
                            if let rate = wallet.adaFiatRate, rate > 0 {
                                let fiat = ada * rate
                                Text(L10n.StoreView.approxFiat(wallet.fiatCurrency.rawValue, fiat))
                                    .vendanoFont(.caption, size: 13)
                                    .foregroundColor(theme.color(named: "TextSecondary"))
                            } else {
                                Text(L10n.StoreView.fiatApproxUnavailable)
                                    .vendanoFont(.caption, size: 13)
                                    .foregroundColor(theme.color(named: "TextSecondary"))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(theme.color(named: "CellBackground"))
                .cornerRadius(14)
            }

            HStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showTapToCollect = true
                } label: {
                    Label(L10n.StoreView.tapToCollect, systemImage: "wave.3.right")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canCollect)
            }

            if state.storeName.isEmpty {
                Text(L10n.StoreView.storeNameSetupHint)
                    .vendanoFont(.caption, size: 13)
                    .foregroundColor(theme.color(named: "TextSecondary"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .onAppear {
            pricingCurrency = state.storeDefaultPricingCurrency
            if wallet.adaFiatRate == nil {
                Task { await wallet.loadPrice() }
            }
        }
        .sheet(isPresented: $showTapToCollect) {
            if let ada = baseAda {
                TapToCollectMerchantView(
                    request: VendanoPaymentRequest(
                        id: UUID().uuidString,
                        createdAt: Date(),
                        expiresAt: Date().addingTimeInterval(60 * 5),
                        storeName: state.storeName.isEmpty ? L10n.StoreView.defaultStoreNameFallback : state.storeName,
                        merchantAddress: state.walletAddress,
                        pricingCurrency: pricingCurrency,
                        fiatCurrencyCode: pricingCurrency == .fiat ? wallet.fiatCurrency.rawValue : nil,
                        fiatSubtotal: pricingCurrency == .fiat ? enteredAmount : nil,
                        exchangeRateFiatPerAda: pricingCurrency == .fiat ? wallet.adaFiatRate : wallet.adaFiatRate,
                        bufferPercent: state.storeExchangeRateBufferPercent,
                        baseAda: ada,
                        tipsEnabled: state.storeTipsEnabled
                    )
                )
                .environmentObject(theme)
            }
        }
    }
}

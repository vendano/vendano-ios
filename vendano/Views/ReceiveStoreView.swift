//
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

    @FocusState private var amountFocused: Bool

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
        baseAda != nil &&
        !(state.storeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) &&
        !state.walletAddress.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                amountCard
                conversionCard

                if state.storeName.isEmpty {
                    Text(L10n.StoreView.storeNameSetupHint)
                        .vendanoFont(.caption, size: 13)
                        .foregroundColor(theme.color(named: "TextSecondary"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture { amountFocused = false }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()

                HStack(spacing: 12) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        amountFocused = false
                        showTapToCollect = true
                    } label: {
                        Label(L10n.StoreView.tapToCollect, systemImage: "wave.3.right")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canCollect)
                }
                .padding(.top, 10)
                .padding(.bottom, 12)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    amountFocused = false
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 17, weight: .semibold))
                }
                .accessibilityLabel("Dismiss keyboard")
            }
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
                        quickPayMatch: QuickPayMatch.random(),
                        storeName: state.storeName.isEmpty ? L10n.StoreView.defaultStoreNameFallback : state.storeName,
                        merchantAddress: state.walletAddress,
                        pricingCurrency: pricingCurrency,
                        fiatCurrencyCode: pricingCurrency == .fiat ? wallet.fiatCurrency.rawValue : nil,
                        fiatSubtotal: pricingCurrency == .fiat ? enteredAmount : nil,
                        exchangeRateFiatPerAda: wallet.adaFiatRate,
                        bufferPercent: state.storeExchangeRateBufferPercent,
                        baseAda: ada,
                        tipsEnabled: state.storeTipsEnabled
                    )
                )
                .environmentObject(theme)
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
//            Text(state.storeName.isEmpty ? L10n.StoreView.storeNameNotSet : state.storeName)
//                .vendanoFont(.headline, size: 22, weight: .bold)
//                .foregroundColor(theme.color(named: "TextPrimary"))
            
            StoreNameDisplay(name: state.storeName)

            Text(L10n.StoreView.acceptPaymentsSubtitle)
                .vendanoFont(.body, size: 14)
                .foregroundColor(theme.color(named: "TextSecondary"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var amountCard: some View {
        VStack(spacing: 10) {
            VStack(spacing: 8) {
                TextField(L10n.StoreView.amountPlaceholder, text: $amountText)
                    .keyboardType(.decimalPad)
                    .focused($amountFocused)
                    .vendanoFont(.title, size: 34, weight: .bold)
                    .foregroundColor(theme.color(named: "TextPrimary"))
                    .multilineTextAlignment(.center)

                Picker("", selection: $pricingCurrency) {
                    Text(wallet.fiatCurrency.rawValue).tag(PricingCurrency.fiat)
                    Text("ADA").tag(PricingCurrency.ada)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            .frame(maxWidth: .infinity) // ensure full-width card content
            .padding(12)
            .background(theme.color(named: "CellBackground"))
            .cornerRadius(14)
        }
    }

    private var conversionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            if pricingCurrency == .fiat {
                if let rate = wallet.adaFiatRate, rate > 0, let ada = baseAda {
                    let bufferedFiat = enteredAmount * (1.0 + state.storeExchangeRateBufferPercent)

                    Text(L10n.StoreView.convertsToAda)
                        .vendanoFont(.caption, size: 13, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextSecondary"))

                    Text("\(ada.formatted(.number.precision(.fractionLength(3 ... 6)))) ADA")
                        .vendanoFont(.headline, size: 20, weight: .bold)
                        .foregroundColor(theme.color(named: "TextPrimary"))

                    Text(
                        L10n.StoreView.rateAndBuffer(
                            wallet.fiatCurrency.rawValue,
                            rate,
                            Int((state.storeExchangeRateBufferPercent * 100).rounded()),
                            bufferedFiat
                        )
                    )
                    .vendanoFont(.caption, size: 13)
                    .foregroundColor(theme.color(named: "TextSecondary"))
                } else {
                    Text(L10n.StoreView.fetchingRate(wallet.fiatCurrency.rawValue))
                        .vendanoFont(.caption, size: 13)
                        .foregroundColor(theme.color(named: "TextSecondary"))

//                    Button(L10n.StoreView.refreshRate) {
//                        Task { await wallet.loadPrice() }
//                    }
//                    .buttonStyle(PrimaryButtonStyle())
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
        .frame(maxWidth: .infinity, alignment: .leading) // full-width
        .padding(12)
        .background(theme.color(named: "CellBackground"))
        .cornerRadius(14)
    }
}

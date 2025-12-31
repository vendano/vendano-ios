//
//  HomeView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var theme: VendanoTheme
    @State private var showSend = false
    @State private var showReceive = false
    @State private var showProfile = false
    @State private var showFAQ = false
    @State private var showFeedback = false
    @State private var showLogoutAlert = false

    @State private var selectedNFT: NFT?

    @StateObject private var state = AppState.shared
    @StateObject private var wallet = WalletService.shared
    @StateObject private var nftVM = NFTGalleryViewModel()

    // how far the main card moves while an overlay is on-screen
    private var verticalOffset: CGFloat {
        switch (showSend, showReceive) {
        case (true, _): return 200   // slide wallet up when Send appears
        case (_, true): return -200  // slide wallet down when Receive appears
        default: return 0
        }
    }

    /// Formats an ADA amount into a string like:
    /// "≈ ₩12,345.67 KRW" using the current fiatCurrency and device locale.
    private func fiatLabel(for adaAmount: Double) -> Text? {
        // For zero, we can show a nice "0.00" even if we haven't loaded a rate yet.
        if adaAmount == 0 {
            let zeroFormatted = 0.0.formatted(
                .number.precision(.fractionLength(2))
            )
            return Text("≈ \(wallet.fiatCurrency.symbol)\(zeroFormatted) \(wallet.fiatCurrency.rawValue)")
        }

        guard let rate = wallet.adaFiatRate else { return nil }

        let fiatValue = adaAmount * rate
        let formatted = fiatValue.formatted(
            .number.precision(.fractionLength(2))
        )
        // Example: "≈ ₩1,234,567.89 KRW"
        return Text("≈ \(wallet.fiatCurrency.symbol)\(formatted) \(wallet.fiatCurrency.rawValue)")
    }

    var body: some View {
        ZStack {
            LightGradientView()

            ScrollView {
                VStack(spacing: 24) {
                    // Header: avatar + name + handle
                    HStack {
                        AvatarThumb(
                            localImage: state.avatar,
                            url: URL(string: state.avatarUrl ?? ""),
                            name: state.displayName,
                            size: 72,
                            tap: { showProfile = true }
                        )
                        VStack(alignment: .leading) {
                            Text(state.displayName.isEmpty ? L10n.Common.unnamed : state.displayName)
                                .vendanoFont(.title, size: 24, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextPrimary"))
                            Text((state.email.count > 0 ? state.email.first : state.phone.first) ?? "")
                                .vendanoFont(.caption, size: 13)
                                .foregroundColor(theme.color(named: "TextSecondary"))
                        }
                        Spacer()
                        Text(L10n.Common.edit)
                            .vendanoFont(.body, size: 16, weight: .semibold)
                            .foregroundColor(theme.color(named: "Accent"))
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showProfile = true
                    }

                    // Main balance card
                    VStack(spacing: 4) {
                        // This is always the honest, stable on-chain total
                        let total = wallet.totalAdaBalance ?? wallet.adaBalance

                        Text(
                            total.formatted(.number.precision(.fractionLength(1)))
                            + " " + L10n.Common.adaUnit
                        )
                        .vendanoFont(.title, size: 48, weight: .heavy)
                        .foregroundColor(theme.color(named: "TextPrimary"))

                        Text(L10n.HomeView.totalOnChainInclStakingTokens)
                            .vendanoFont(.caption, size: 13)
                            .foregroundColor(theme.color(named: "TextSecondary"))

                        if let fiatText = fiatLabel(for: total) {
                            fiatText
                                .vendanoFont(.headline, size: 18, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextSecondary"))
                        }
                    }

                    // HOSKY section
                    if wallet.hoskyBalance > 0 {
                        VStack(spacing: 2) {
                            Text(
                                L10n.Common.hoskyToken + " " +
                                wallet.hoskyBalance.formatted(
                                    .number.precision(.fractionLength(0))
                                )
                            )
                            .vendanoFont(.headline, size: 18, weight: .semibold)
                            .foregroundColor(theme.color(named: "TextPrimary"))

                            // Still worth 0, but in their chosen fiat with proper formatting
                            if let hoskyFiatText = fiatLabel(for: 0) {
                                hoskyFiatText
                                    .vendanoFont(.body, size: 16)
                                    .foregroundColor(theme.color(named: "TextSecondary"))
                            }
                        }
                    }

                    // Send / Receive buttons
                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.easeInOut) { showSend = true }
                        } label: {
                            Label(L10n.HomeView.send, systemImage: "arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button {
                            withAnimation(.easeInOut) { showReceive = true }
                        } label: {
                            Label(L10n.HomeView.receive, systemImage: "arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }

                    if !nftVM.nfts.isEmpty {
                        NFTThumbnailRow(selectedNFT: $selectedNFT)
                    }

                    ActivityView()

                    Spacer()
                }
                .padding()
                .offset(y: verticalOffset)
                .animation(.easeInOut, value: showSend || showReceive)
            }
            .refreshable {
                // re-fetch balances & history
                state.refreshOnChainData()
            }
            .background(Color.clear)
            .scrollContentBackground(.hidden)
            .ignoresSafeArea(edges: .bottom)

            // Overlays: Send / Receive
            if showSend {
                SendView {
                    withAnimation(.easeInOut) {
                        AnalyticsManager.logEvent("send_view_display")
                        showSend = false
                    }
                }
                .transition(.move(edge: .top))
                .zIndex(1)
            }

            if showReceive {
                ReceiveView {
                    withAnimation(.easeInOut) {
                        AnalyticsManager.logEvent("receive_view_display")
                        showReceive = false
                    }
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        .task {
            await nftVM.loadNFTs()
        }
        .onChange(of: state.walletAddress) { _, _ in
            Task { await nftVM.loadNFTs() }
        }
        .onChange(of: state.sendToAddress) { _, newDraft in
            if newDraft != nil {
                withAnimation(.easeInOut) {
                    showSend = true
                }
            }
        }
        .toolbar {
            if !showSend && !showReceive {
                // feedback “!” button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFeedback = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                    }
                    .foregroundColor(theme.color(named: "Accent"))
                }
                // FAQ “?” button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFAQ = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .foregroundColor(theme.color(named: "Accent"))
                }
                // Logout button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLogoutAlert = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                    .foregroundColor(theme.color(named: "Accent"))
                    .alert(L10n.HomeView.removeThisWalletFromThisDevice, isPresented: $showLogoutAlert) {
                        Button(L10n.Common.cancel, role: .cancel) {}
                        Button(L10n.Common.remove, role: .destructive) {
                            state.removeWallet()
                        }
                    } message: {
                        Text(L10n.HomeView.thisAppWillForgetYourWalletOnThis)
                            .vendanoFont(.body, size: 16)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .automatic)
        .sheet(isPresented: $showProfile) { ProfileSheet() }
        .sheet(isPresented: $showFAQ) {
            FAQView(faqs: state.allFAQs, onFinish: { showFAQ = false })
                .environmentObject(state)
        }
        .sheet(isPresented: $showFeedback) { FeedbackSheet() }
        .sheet(item: $selectedNFT) { nft in
            NFTDetailSheet(nft: nft) {
                withAnimation(.easeInOut) { selectedNFT = nil }
            }
            .zIndex(1)
        }
        .onChange(of: state.avatarUrl) { _, _ in
            Task { await state.reloadAvatarIfNeeded() }
        }
    }
}

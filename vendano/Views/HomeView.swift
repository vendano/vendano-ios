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
        case (true, _): return 200 // slide wallet up when Send appears
        case (_, true): return -200 // slide wallet down when Receive appears
        default: return 0
        }
    }

    var body: some View {
        ZStack {
            LightGradientView()

            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        AvatarThumb(
                            localImage: state.avatar,
                            url: URL(string: state.avatarUrl ?? ""),
                            name: state.displayName,
                            size: 72,
                            tap: { showProfile = true }
                        )
                        VStack(alignment: .leading) {
                            Text(state.displayName.isEmpty ? "Unnamed" : state.displayName)
                                .vendanoFont(.title, size: 24, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextPrimary"))
                            Text((state.email.count > 0 ? state.email.first : state.phone.first) ?? "")
                                .vendanoFont(.caption, size: 13)
                                .foregroundColor(theme.color(named: "TextSecondary"))
                        }
                        Spacer()
                        Text("Edit")
                            .vendanoFont(.body, size: 16, weight: .semibold)
                            .foregroundColor(theme.color(named: "Accent"))
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showProfile = true
                    }

                    VStack(spacing: 2) {
                        Text("\(wallet.adaBalance.truncating(toPlaces: 1)) ADA")
                            .vendanoFont(.title, size: 48, weight: .heavy)
                            .foregroundColor(theme.color(named: "TextPrimary"))
                        if let usdRate = WalletService.shared.adaUsdRate {
                            Text("≈ $\(wallet.adaBalance * usdRate, format: .number.precision(.fractionLength(2))) USD")
                                .vendanoFont(.headline, size: 18, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextSecondary"))
                        }
                    }

                    if wallet.hoskyBalance > 0 {
                        VStack(spacing: 2) {
                            Text("HOSKY \(wallet.hoskyBalance, format: .number.precision(.fractionLength(0)))")
                                .vendanoFont(.headline, size: 18, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextPrimary"))
                            Text("≈ $\(wallet.hoskyBalance * 0, format: .number.precision(.fractionLength(2))) USD")
                                .vendanoFont(.body, size: 16)
                                .foregroundColor(theme.color(named: "TextSecondary"))
                        }
                    }

                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.easeInOut) { showSend = true }
                        } label: {
                            Label("Send", systemImage: "arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button {
                            withAnimation(.easeInOut) { showReceive = true }
                        } label: {
                            Label("Receive", systemImage: "arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }

                    // TODO: enable NFT view
                    // - test with NFTs
                    // - view sheet, set PFP
                    
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

            if showSend {
                SendView {
                    withAnimation(.easeInOut) { showSend = false }
                }
                .transition(.move(edge: .top))
                .zIndex(1)
            }

            if showReceive {
                ReceiveView {
                    withAnimation(.easeInOut) { showReceive = false }
                }
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
        .toolbar {
            if showSend == false && showReceive == false {
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
                    .alert("Remove your wallet?", isPresented: $showLogoutAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Remove", role: .destructive) {
                            state.removeWallet()
                        }
                    } message: {
                        Text("This app will forget your wallet. Your funds remain secure on the blockchain, but you won’t see your balance until you restore it with your 24-word recovery phrase.")
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
            FAQView(faqs: FAQs.shared.fullFAQs(), onFinish: { showFAQ = false })
                .environmentObject(state)
        }
        .sheet(isPresented: $showFeedback) { FeedbackSheet() }
        .sheet(item: $selectedNFT) { nft in
            NFTDetailSheet(nft: nft)
        }
        .onChange(of: state.avatarUrl) { _, _ in
            Task { await state.reloadAvatarIfNeeded() }
        }
    }
}

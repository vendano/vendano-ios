//
//  HomeView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import SwiftUI

struct HomeView: View {
    @State private var showSend = false
    @State private var showReceive = false
    @State private var showProfile = false
    @State private var showFAQ = false
    @State private var showFeedback = false
    @State private var showLogoutAlert = false

    @StateObject private var state = AppState.shared

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
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color("TextPrimary"))
                            Text((state.email.count > 0 ? state.email.first : state.phone.first) ?? "")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Edit")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("Accent"))
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showProfile = true
                    }

                    VStack(spacing: 2) {
                        Text("\(state.adaBalance.truncating(toPlaces: 1)) ADA")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(Color("TextPrimary"))
                        if let usdRate = WalletService.shared.adaUsdRate {
                            Text("≈ $\(state.adaBalance * usdRate, format: .number.precision(.fractionLength(2))) USD")
                                .font(.subheadline)
                                .foregroundColor(Color("TextSecondary"))
                        }
                    }

                    if state.hoskyBalance > 0 {
                        VStack(spacing: 2) {
                            Text("HOSKY \(state.hoskyBalance, format: .number.precision(.fractionLength(0)))")
                                .font(.headline)
                                .foregroundColor(Color("TextPrimary"))
                            Text("≈ $\(state.hoskyBalance * 0, format: .number.precision(.fractionLength(2))) USD")
                                .font(.subheadline)
                                .foregroundColor(Color("TextSecondary"))
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

                    ActivityView()

                    Spacer()
                }
                .padding()
                .offset(y: verticalOffset)
                .animation(.easeInOut, value: showSend || showReceive)

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
            .refreshable {
                // re-fetch balances & history
                state.refreshOnChainData()
            }
            .ignoresSafeArea(edges: .bottom)
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
                    .foregroundColor(Color("Accent"))
                }
                // FAQ “?” button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFAQ = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .foregroundColor(Color("Accent"))
                }
                // Logout button

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLogoutAlert = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                    .foregroundColor(Color("Accent"))
                    .alert("Remove your wallet?", isPresented: $showLogoutAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Remove", role: .destructive) {
                            state.walletAddress = ""
                            state.adaBalance = 0
                            state.hoskyBalance = 0
                            state.seedWords = []

                            KeychainWrapper.standard.removeObject(forKey: "seedWords")

                            state.onboardingStep = .walletChoice
                        }
                    } message: {
                        Text("This app will forget your wallet. Your funds remain secure on the blockchain, but you won’t see your balance until you restore it with your 24-word recovery phrase.")
                    }
                }
            }
        }
        .sheet(isPresented: $showProfile) { ProfileSheet() }
        .sheet(isPresented: $showFAQ) {
            FAQView(faqs: FAQs.shared.fullFAQs(), onFinish: { showFAQ = false })
                .environmentObject(state)
        }
        .sheet(isPresented: $showFeedback) { FeedbackSheet() }
        .onChange(of: state.avatarUrl) { _, _ in
            Task { await state.reloadAvatarIfNeeded() }
        }
    }
}

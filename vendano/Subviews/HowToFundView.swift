//
//  HomeEmptyFundingCards.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 1/2/26.
//

import SwiftUI
import UIKit

enum AddAdaPath: String, Identifiable {
    case askFriend
    case transfer
    case buy

    var id: String { rawValue }
}

struct HowToFundView: View {
    @EnvironmentObject var theme: VendanoTheme

    let walletAddress: String
    let onOpenReceive: () -> Void
    let onOpenBuyAda: () -> Void

    @State private var didCopyAddress = false
    @State private var copyResetTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            VStack(spacing: 12) {
                ActionCard(
                    icon: "person.2.fill",
                    badge: L10n.HomeEmptyFunding.badgeEasiest,
                    title: L10n.HomeEmptyFunding.cardAskFriendTitle,
                    subtitle: L10n.HomeEmptyFunding.cardAskFriendSubtitle,
                    buttonTitle: L10n.HomeEmptyFunding.cardAskFriendCta,
                    isEmphasized: true,
                    ctaBackground: theme.color(named: "Accent"),
                    ctaForeground: theme.color(named: "TextReversed")
                ) {
                    AnalyticsManager.logEvent("home_empty_addada_request")
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onOpenReceive()
                }

                ActionCard(
                    icon: "doc.on.doc",
                    badge: nil,
                    title: L10n.HomeEmptyFunding.cardTransferTitle,
                    subtitle: L10n.HomeEmptyFunding.cardTransferSubtitle,
                    buttonTitle: didCopyAddress
                        ? L10n.HomeEmptyFunding.addressCopiedCta
                        : L10n.HomeEmptyFunding.cardTransferCta,
                    isEmphasized: false,
                    // “Copied” state uses a calmer background so it clearly changes.
                    ctaBackground: didCopyAddress
                        ? theme.color(named: "FieldBackground")
                        : theme.color(named: "Accent"),
                    ctaForeground: didCopyAddress
                        ? theme.color(named: "TextPrimary")
                        : theme.color(named: "TextReversed")
                ) {
                    copyWalletAddress()
                }

                ActionCard(
                    icon: "creditcard.fill",
                    badge: L10n.HomeEmptyFunding.badgeRecommended,
                    title: L10n.HomeEmptyFunding.cardBuyTitle,
                    subtitle: L10n.HomeEmptyFunding.cardBuySubtitle,
                    buttonTitle: L10n.HomeEmptyFunding.cardBuyCta,
                    isEmphasized: false,
                    ctaBackground: theme.color(named: "Accent"),
                    ctaForeground: theme.color(named: "TextReversed")
                ) {
                    AnalyticsManager.logEvent("home_empty_addada_buy")
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onOpenBuyAda()
                }
            }
        }
        .padding(16)
        .background(theme.color(named: "CellBackground"))
        .cornerRadius(16)
        .accessibilityElement(children: .contain)
    }

    private func copyWalletAddress() {
        AnalyticsManager.logEvent("home_empty_addada_copy_address")
        UIPasteboard.general.string = walletAddress
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.easeInOut(duration: 0.15)) {
            didCopyAddress = true
        }

        // Reset after 3 seconds (and restart the timer if tapped again)
        copyResetTask?.cancel()
        copyResetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation(.easeInOut(duration: 0.25)) {
                didCopyAddress = false
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.HomeEmptyFunding.title)
                .vendanoFont(.headline, size: 18, weight: .semibold)
                .foregroundColor(theme.color(named: "TextPrimary"))

            Text(L10n.HomeEmptyFunding.subtitle)
                .vendanoFont(.body, size: 15)
                .foregroundColor(theme.color(named: "TextSecondary"))

            Text(L10n.HomeEmptyFunding.tip)
                .vendanoFont(.caption, size: 13)
                .foregroundColor(theme.color(named: "TextSecondary"))
                .padding(.top, 2)
        }
    }

    // MARK: - Card

    private struct ActionCard: View {
        @EnvironmentObject var theme: VendanoTheme

        let icon: String
        let badge: String?
        let title: String
        let subtitle: String
        let buttonTitle: String
        let isEmphasized: Bool
        let ctaBackground: Color
        let ctaForeground: Color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(alignment: .top, spacing: 12) {
                    iconView

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(title)
                                .vendanoFont(.headline, size: 16, weight: .semibold)
                                .foregroundColor(theme.color(named: "TextPrimary"))

                            if let badge {
                                Text(badge)
                                    .vendanoFont(.caption, size: 12, weight: .semibold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(theme.color(named: "FieldBackground"))
                                    .cornerRadius(999)
                                    .foregroundColor(theme.color(named: "TextPrimary"))
                                    .accessibilityHidden(true)
                            }
                        }

                        Text(subtitle)
                            .vendanoFont(.body, size: 14)
                            .foregroundColor(theme.color(named: "TextSecondary"))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack {
                            Text(buttonTitle)
                                .vendanoFont(.body, size: 15, weight: .semibold)
                                .foregroundColor(ctaForeground)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(ctaBackground)
                                .cornerRadius(10)
                                .animation(.easeInOut(duration: 0.15), value: buttonTitle)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(theme.color(named: "TextSecondary"))
                                .imageScale(.small)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(backgroundColor)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(borderColor, lineWidth: isEmphasized ? 1.5 : 1.0)
                )
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel("\(title). \(subtitle)")
        }

        private var iconView: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.color(named: "FieldBackground"))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.color(named: "Accent"))
            }
            .padding(.top, 2)
        }

        private var backgroundColor: Color {
            isEmphasized
            ? theme.color(named: "FieldBackground").opacity(0.7)
            : theme.color(named: "CellBackground")
        }

        private var borderColor: Color {
            isEmphasized
            ? theme.color(named: "Accent").opacity(0.55)
            : theme.color(named: "FieldBackground").opacity(0.9)
        }
    }
}

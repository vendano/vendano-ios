//
//  NotificationPrimerCard.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 1/2/26.
//

import SwiftUI

struct NotificationPrimerCard: View {
    @EnvironmentObject var theme: VendanoTheme
    let onEnable: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(theme.color(named: "Accent"))

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.NotificationPrimerCard.title)
                    .vendanoFont(.headline, size: 16, weight: .semibold)
                    .foregroundColor(theme.color(named: "TextPrimary"))

                Text(L10n.NotificationPrimerCard.details)
                    .vendanoFont(.caption, size: 13)
                    .foregroundColor(theme.color(named: "TextSecondary"))

                HStack(spacing: 10) {
                    Button(L10n.Common.enable, action: onEnable)
                        .buttonStyle(.borderedProminent)

                    Button(L10n.Common.notNow, action: onNotNow)
                        .buttonStyle(.bordered)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(theme.color(named: "CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

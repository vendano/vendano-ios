//
//  TransactionRow.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/27/25.
//

import SwiftUI

struct TransactionRow: View {
    @EnvironmentObject var theme: VendanoTheme
    let tx: TxRowViewModel
    var body: some View {
        HStack {
            // avatar / wallet icon
            if (tx.avatarURL != nil) || (tx.name != nil) {
                AvatarThumb(
                    localImage: nil,
                    url: tx.avatarURL,
                    name: tx.name,
                    size: 36,
                    tap: {}
                )
            } else {
                ZStack {
                    Circle().fill(theme.color(named: "TextSecondary"))
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 16))
                        .foregroundColor(theme.color(named: "FieldBackground"))
                }
                .frame(width: 36, height: 36)
            }

            // name or address
            Text(tx.name ?? tx.counterpartyAddress.truncated())
                .vendanoFont(.body, size: 16)
                .foregroundColor(theme.color(named: "TextPrimary"))

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(tx.outgoing ? "+" : "-")\(tx.amount, specifier: "%.1f")₳")
                    .monospacedDigit()
                    .vendanoFont(.body, size: 16)
                    .foregroundColor(tx.outgoing ? theme.color(named: "Positive") : theme.color(named: "Negative"))

                Text("\(tx.balanceAfter, specifier: "%.1f")₳")
                    .vendanoFont(.caption, size: 13)
                    .foregroundColor(theme.color(named: "TextSecondary"))
            }
        }
    }
}

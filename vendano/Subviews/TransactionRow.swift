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
                Text("\(tx.outgoing ? "-" : "+")\((tx.amount).formatted(.number.precision(.fractionLength(1))))₳")
                    .monospacedDigit()
                    .vendanoFont(.body, size: 16)
                    .foregroundColor(
                        tx.outgoing
                        ? theme.color(named: "Negative")   // sent
                        : theme.color(named: "Positive")   // received
                    )

                Text("\((tx.balanceAfter).formatted(.number.precision(.fractionLength(1))))₳")
                    .vendanoFont(.caption, size: 13)
                    .foregroundColor(theme.color(named: "TextSecondary"))
            }
        }
    }
}

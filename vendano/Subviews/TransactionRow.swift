//
//  TransactionRow.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/27/25.
//

import SwiftUI

struct TransactionRow: View {
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
                    Circle().fill(Color("TextSecondary"))
                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color("FieldBackground"))
                }
                .frame(width: 36, height: 36)
            }

            // name or address
            Text(tx.name ?? tx.counterpartyAddress.truncated())
                .font(.body)
                .foregroundColor(Color("TextPrimary"))

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(tx.outgoing ? "+" : "-")\(tx.amount, specifier: "%.1f")₳")
                    .monospacedDigit()
                    .font(.body)
                    .foregroundColor(tx.outgoing ? Color("Positive") : Color("Negative"))

                Text("\(tx.balanceAfter, specifier: "%.1f")₳")
                    .font(.footnote)
                    .foregroundColor(Color("TextSecondary"))
            }
        }
    }
}

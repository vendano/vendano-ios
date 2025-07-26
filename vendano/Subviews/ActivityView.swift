//
//  ActivityView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/26/25.
//

import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var theme: VendanoTheme
    @StateObject private var state = AppState.shared

    // helper: group by start‐of‐day
    private var groupedTxs: [(date: Date, txs: [TxRowViewModel])] {
        let calendar = Calendar.current
        let groups = Dictionary(
            grouping: state.recentTxs
        ) { calendar.startOfDay(for: $0.date) }

        return groups
            .map { (date: $0.key, txs: $0.value) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if state.checkingTxs {
                Spacer()
                
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(theme.color(named: "TextPrimary"))
                
                Spacer()
            } else if state.recentTxs.isEmpty {
                Spacer()
                Text("No transaction history found.")
                    .vendanoFont(.headline, size: 18, weight: .semibold)
                    .foregroundColor(theme.color(named: "TextPrimary"))
                Spacer()
            } else {
                Text("Recent activity")
                    .vendanoFont(.headline, size: 18, weight: .semibold)
                    .foregroundColor(theme.color(named: "TextPrimary"))

                ScrollView {
                    LazyVStack(spacing: 12, pinnedViews: .sectionHeaders) {
                        ForEach(groupedTxs, id: \.date) { group in
                            Section(header:
                                Text(group.date, style: .date)
                                    .vendanoFont(.caption, size: 13)
                                    .foregroundColor(theme.color(named: "TextSecondary"))
                                    .padding(.horizontal)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            ) {
                                VStack {
                                    ForEach(Array(group.txs.enumerated()), id: \.element.id) { index, tx in
                                        if index > 0 {
                                            Divider()
                                                .padding(.vertical, 8)
                                        }
                                        TransactionRow(tx: tx)
                                    }
                                }
                                .padding()
                                .background(theme.color(named: "CellBackground"))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
    }
}

//
//  SheetChrome.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 1/3/26.
//

import SwiftUI

struct SheetChrome<Content: View>: View {
    @EnvironmentObject var theme: VendanoTheme
    let onClose: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content()
                .padding(.top, 44)

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(theme.color(named: "TextReversed").opacity(0.7))
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityLabel("Close")
            }
            .padding(.top, 12)
            .padding(.trailing, 12)
        }
    }
}

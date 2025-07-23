//
//  PlaceholderCell.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/23/25.
//

import SwiftUI

struct PlaceholderCell: View {
    @EnvironmentObject var theme: VendanoTheme

    var body: some View {
        Image(VendanoTheme.shared.isHosky() ? "vendoggo-logo" : "vendano-logo")
            .resizable()
            .scaledToFit()
            .opacity(0.3)
            .padding(8)
            .frame(width: 60, height: 60)
            .background(theme.color(named: "CellBackground"))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 1)
            )
    }
}

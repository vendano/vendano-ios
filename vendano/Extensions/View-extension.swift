//
//  View-extension.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/13/25.
//

import SwiftUI

extension View {
    func vendanoFont(_ style: VendanoTheme.TextStyle, size: CGFloat, weight: Font.Weight = .regular) -> some View {
        font(VendanoTheme.shared.font(style, size: size, weight: weight))
    }
}

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
    
    func keyboardAware(using guardian: KeyboardGuardian) -> some View {
        self
            .padding(.bottom, guardian.height)
            .animation(.easeOut(duration: 0.25), value: guardian.height)
    }
    
}

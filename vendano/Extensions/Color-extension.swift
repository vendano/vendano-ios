//
//  Color-extension.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/13/25.
//

import SwiftUI

extension Color {
    @MainActor
    init(themed key: String) {
        self = VendanoTheme.shared.color(named: key)
    }
}

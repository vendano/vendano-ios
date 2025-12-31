//
//  Double-extension.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/27/25.
//

import Foundation

extension Double {
    func truncating(toPlaces places: Int) -> String {
        let multiplier = pow(10.0, Double(places))
        let truncated = Double(Int(self * multiplier)) / multiplier
        return truncated.formatted(.number.precision(.fractionLength(places)))
    }
}

//
//  UIApplication-extension.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/6/25.
//

import Foundation
import UIKit

extension UIApplication {
    func endEditing() {
        sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

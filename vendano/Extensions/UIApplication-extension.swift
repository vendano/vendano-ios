//
//  UIApplication-extension.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 8/30/25.
//

import UIKit

extension UIApplication {
    var firstKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }
}

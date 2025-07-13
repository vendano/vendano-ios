//
//  UIImage-extension.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/17/25.
//

import UIKit

extension UIImage {
    func resize(to dim: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: dim, height: dim))
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: CGSize(width: dim, height: dim)))
        }
    }
}

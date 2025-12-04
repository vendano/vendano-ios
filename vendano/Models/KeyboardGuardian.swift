//
//  KeyboardGuardian.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/21/25.
//

import UIKit
import SwiftUI

final class KeyboardGuardian: ObservableObject {
    @Published var height: CGFloat = 0

    private var showObserver: NSObjectProtocol?
    private var hideObserver: NSObjectProtocol?

    init() {
        let nc = NotificationCenter.default

        showObserver = nc.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard
                let self,
                let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            else { return }

            // Defer the @Published change to the next run loop
            DispatchQueue.main.async {
                self.height = frame.height
            }
        }

        hideObserver = nc.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }

            // Same: update outside the current view update cycle
            DispatchQueue.main.async {
                self.height = 0
            }
        }
    }

    deinit {
        let nc = NotificationCenter.default
        if let showObserver {
            nc.removeObserver(showObserver)
        }
        if let hideObserver {
            nc.removeObserver(hideObserver)
        }
    }
}

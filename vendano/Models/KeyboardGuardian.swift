//
//  KeyboardGuardian.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/21/25.
//

import UIKit

final class KeyboardGuardian: ObservableObject {
    @Published var height: CGFloat = 0

    private var show: NSObjectProtocol?
    private var hide: NSObjectProtocol?

    init() {
        let nc = NotificationCenter.default

        show = nc.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil, queue: .main
        ) { note in
            guard let frame =
                note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                    as? CGRect else { return }
            self.height = frame.height
        }

        hide = nc.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil, queue: .main
        ) { _ in self.height = 0 }
    }

    deinit {
        if let show { NotificationCenter.default.removeObserver(show) }
        if let hide { NotificationCenter.default.removeObserver(hide) }
    }
}

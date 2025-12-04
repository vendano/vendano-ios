//
//  BlurOverlay.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/6/25.
//

import SwiftUI

class BlurOverlay: ObservableObject {
    private var blurWindow: UIWindow?

    init() {
        let nc = NotificationCenter.default

        nc.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.presentBlur()
            }
        }

        nc.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.removeBlur()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @MainActor
    private func presentBlur() {
        guard blurWindow == nil else { return }

        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0 is UIWindowScene }) as? UIWindowScene
        else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
        let host = UIHostingController(
            rootView: BlurView()
                .environmentObject(VendanoTheme.shared)
        )
        host.view.backgroundColor = .clear

        window.rootViewController = host
        window.windowLevel = .alert + 1
        window.makeKeyAndVisible()

        blurWindow = window
    }

    @MainActor
    private func removeBlur() {
        blurWindow?.isHidden = true
        blurWindow = nil
    }
}

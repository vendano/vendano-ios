//
//  BlurOverlay.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/6/25.
//

import SwiftUI

class BlurOverlay: ObservableObject {
    private var blurHostView: UIView?

    init() {
        let nc = NotificationCenter.default
        
        nc.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.presentBlur()
            }
        }
        
        nc.addObserver(forName: UIApplication.didBecomeActiveNotification,
                       object: nil, queue: .main) { _ in self.removeBlur() }
    }

    @MainActor
    private func presentBlur() {
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first

        if let windowScene = scene as? UIWindowScene {
            let host = UIHostingController(
                rootView: BlurView()
                    .environmentObject(VendanoTheme.shared)
            )
            host.view.frame = windowScene.coordinateSpace.bounds
            host.view.isUserInteractionEnabled = false
            blurHostView = host.view

            windowScene.keyWindow?.rootViewController?.view.addSubview(host.view)
        }
    }

    private func removeBlur() {
        blurHostView?.removeFromSuperview()
    }
}

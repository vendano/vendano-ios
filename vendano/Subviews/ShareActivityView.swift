//
//  ShareActivityView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/28/25.
//

import SwiftUI

struct ShareActivityView: UIViewControllerRepresentable {
    @EnvironmentObject var theme: VendanoTheme
    typealias UIViewControllerType = UIActivityViewController

    let activityItems: [Any]

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )

        if let pop = controller.popoverPresentationController {
            // Find the first connected UIWindowScene
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                let root = scene.windows.first {
                pop.sourceView = root
                pop.sourceRect = CGRect(
                    x: root.bounds.midX,
                    y: root.bounds.midY,
                    width: 0, height: 0
                )
                pop.permittedArrowDirections = []
            }
        }

        return controller
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {
        // nothing to do
    }
}

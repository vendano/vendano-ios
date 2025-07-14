//
//  MessageComposeView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/29/25.
//

import Foundation
import MessageUI
import SwiftUI

struct MessageComposeView: UIViewControllerRepresentable {
    @EnvironmentObject var theme: VendanoTheme
    @Environment(\.presentationMode) var presentation
    let recipients: [String]
    let body: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = recipients
        vc.body = body
        vc.messageComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_: MFMessageComposeViewController, context _: Context) {}

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageComposeView
        init(_ parent: MessageComposeView) { self.parent = parent }
        func messageComposeViewController(_: MFMessageComposeViewController,
                                          didFinishWith _: MessageComposeResult) {
            parent.presentation.wrappedValue.dismiss()
        }
    }
}

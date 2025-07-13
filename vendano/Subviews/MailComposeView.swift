//
//  MailComposeView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/29/25.
//

import MessageUI
import SwiftUI

struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentation
    let recipients: [String]
    let subject: String
    let body: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_: MFMailComposeViewController, context _: Context) {}

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        init(_ parent: MailComposeView) { self.parent = parent }
        func mailComposeController(_: MFMailComposeViewController,
                                   didFinishWith _: MFMailComposeResult,
                                   error _: Error?) {
            parent.presentation.wrappedValue.dismiss()
        }
    }
}

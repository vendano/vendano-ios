//
//  MessageRow.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/9/25.
//

import SwiftUI

struct MessageRow: View {
    @EnvironmentObject var theme: VendanoTheme
    let message: FeedbackMessage

    private var isMe: Bool {
        // FirebaseService.shared.user?.uid == message.uid
        !message.fromDeveloper
    }

    var body: some View {
        HStack {
            if isMe { Spacer() }
            Text(message.text)
                .vendanoFont(.body, size: 16)
                .padding(10)
                .background(isMe ? theme.color(named: "BackgroundStart") : theme.color(named: "BackgroundEnd"))
                .foregroundColor(theme.color(named: "TextPrimary"))
                .cornerRadius(12)
                .frame(maxWidth: .infinity, alignment: isMe ? .trailing : .leading)
            if !isMe { Spacer() }
        }
        .padding(.vertical, 2)
    }
}

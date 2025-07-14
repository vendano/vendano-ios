//
//  FAQSheet.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/6/25.
//

import SwiftUI

struct FAQSheet: View {
    @EnvironmentObject var theme: VendanoTheme
    let faq: FAQItem
    let onDismiss: () -> Void

    // 0 = Answer, 1 = Clarify, 2 = Details
    @State private var level: Int = 0
    private let segments = ["Quick", "Explain", "Deep Dive"]

    var body: some View {
        ZStack {
            LightGradientView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView { // Content area
                    VStack(alignment: .leading, spacing: 16) {
                        // Question (title)
                        Text(faq.question)
                            .vendanoFont(.body, size: 12, weight: .bold)
                            .foregroundColor(theme.color(named: "TextPrimary"))
                            .multilineTextAlignment(.leading)

                        // TL;DR chip
                        HStack {
                            Spacer()

                            HStack(spacing: 6) {
                                if faq.icon.count == 1 {
                                    Text(faq.icon)
                                        .font(.system(size: 32))
                                        .foregroundColor(theme.color(named: "Accent"))
                                        .padding(.leading)
                                } else {
                                    Image(systemName: faq.icon)
                                        .font(.system(size: 32))
                                        .foregroundColor(theme.color(named: "Accent"))
                                        .padding(.leading)
                                }

                                Text(faq.tldr)
                                    .vendanoFont(.title, size: 22, weight: .semibold)
                                    .foregroundColor(theme.color(named: "TextPrimary"))
                                    .padding()
                            }
                            .padding(4)
                            .overlay(
                                Capsule().stroke(theme.color(named: "Accent"), lineWidth: 1)
                            )

                            Spacer()
                        }

                        Picker("", selection: $level) {
                            ForEach(0 ..< segments.count, id: \ .self) { idx in
                                Text(segments[idx]).tag(idx)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(4)

                        // Content text, based on selected segment
                        Text(currentContent)
                            .vendanoFont(.body, size: 16)
                            .foregroundColor(theme.color(named: "TextPrimary"))
                            .lineSpacing(4)
                    }
                    .padding()
                }

                Button("Close") {
                    onDismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .padding()
        }
    }

    private var currentContent: String {
        switch level {
        case 1: return faq.clarify
        case 2: return faq.details
        default: return faq.answer
        }
    }
}

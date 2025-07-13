//
//  FAQSheet.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/6/25.
//

import SwiftUI

struct FAQSheet: View {
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
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color("TextPrimary"))
                            .multilineTextAlignment(.leading)

                        // TL;DR chip
                        HStack {
                            Spacer()

                            HStack(spacing: 6) {
                                if faq.icon.count == 1 {
                                    Text(faq.icon)
                                        .font(.system(size: 32))
                                        .foregroundColor(Color("Accent"))
                                        .padding(.leading)
                                } else {
                                    Image(systemName: faq.icon)
                                        .font(.system(size: 32))
                                        .foregroundColor(Color("Accent"))
                                        .padding(.leading)
                                }

                                Text(faq.tldr)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(Color("TextPrimary"))
                                    .padding()
                            }
                            .padding(4)
                            .overlay(
                                Capsule().stroke(Color("Accent"), lineWidth: 1)
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
                            .font(.system(size: 16))
                            .foregroundColor(Color("TextPrimary"))
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

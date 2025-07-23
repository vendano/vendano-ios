//
//  FeedbackSheet.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/6/25.
//

import SwiftUI

struct FeedbackSheet: View {
    @EnvironmentObject var theme: VendanoTheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var vm = FeedbackViewModel()
    @State private var text = ""
    @State private var prompt = ""
    @FocusState private var focus: Bool

    private let emptyPrompts = [
        "Got feedback or ideas? We’d love to hear how we can make Vendano better for you.",
        "Questions, praise, bugs - everything helps. Share what’s on your mind!",
        "Your insight shapes this app. Tell us what’s working or where we can improve...",
        "Wondering how to use Vendano? Ask away or let us know what you think so far.",
        "Help us build a better experience - your feedback makes a difference!",
    ]

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Contact Us")
                        .vendanoFont(.title, size: 24, weight: .semibold)
                        .foregroundColor(theme.color(named: "TextReversed"))
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(theme.color(named: "TextReversed").opacity(0.7))
                    }
                }
                .padding()

                if vm.messages.isEmpty {
                    VStack {
                        Spacer()
                        Text(prompt)
                            .vendanoFont(.body, size: 16)
                            .foregroundColor(theme.color(named: "TextReversed"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)

                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(vm.messages) { msg in
                                    MessageRow(message: msg)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .onChange(of: vm.messages) { _, _ in
                            if let first = vm.messages.first {
                                proxy.scrollTo(first.id, anchor: .top)
                            }
                        }
                    }
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                Divider()
                    .background(theme.color(named: "CellBackground"))

                HStack(spacing: 12) {
                    TextEditor(text: $text)
                        .vendanoFont(.body, size: 18)
                        .foregroundColor(theme.color(named: "TextPrimary"))
                        .padding(8)
                        .background(theme.color(named: "FieldBackground"))
                        .cornerRadius(8)
                        .frame(minHeight: 40, maxHeight: 80)
                        .focused($focus)

                    Button(action: {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.lowercased() == "debug" {
                            let log = DebugLogger.getLogWithDeviceInfo()
                            vm.send("DEBUG LOG:\n\(log)")
                            DebugLogger.clear()
                            text = ""
                        } else {
                            vm.send(text)
                            text = ""
                        }

                        focus = true
                    }) {
                        Image(systemName: "paperplane.fill")
                            .frame(width: 24, height: 24)
                            .foregroundColor(theme.color(named: "Accent"))
                            .padding(10)
                            .background(Circle().fill(theme.color(named: "TextReversed")))
                    }
                    .buttonStyle(.plain)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .padding(.bottom)
        }
        .onAppear {
            prompt = emptyPrompts.randomElement() ?? ""
            focus = true
        }
    }
}

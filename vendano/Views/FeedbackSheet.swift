//
//  FeedbackSheet.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/6/25.
//

import SwiftUI

struct FeedbackSheet: View {
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
        "Help us build a better experience - your feedback makes a difference!"
    ]

    var body: some View {
        ZStack {
            DarkGradientView()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Contact Us")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color("TextReversed"))
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("TextReversed").opacity(0.7))
                    }
                }
                .padding()

                if vm.messages.isEmpty {
                    // 3️⃣ Centered empty state
                    VStack {
                        Spacer()
                        Text(prompt)
                            .font(.footnote)
                            .foregroundColor(Color("TextReversed"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)

                } else {
                    // 3) Chat messages list
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

                // 4) Divider
                Divider()
                    .background(Color("CellBackground"))

                // 5) Input field + Send button
                HStack(spacing: 12) {
                    TextEditor(text: $text)
                        .font(.system(size: 16))
                        .foregroundColor(Color("TextPrimary"))
                        .padding(8)
                        .background(Color("FieldBackground"))
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
                            .foregroundColor(Color("Accent"))
                            .padding(10)
                            .background(Circle().fill(Color("TextReversed")))
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

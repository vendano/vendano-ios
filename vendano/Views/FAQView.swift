//
//  FAQView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import SwiftUI

struct FAQRow: View {
    let faq: FAQItem
    let viewed: Bool
    let expanded: Bool

    var body: some View {
        HStack(spacing: 12) {
            if faq.icon.count == 1 {
                Text(faq.icon)
                    .foregroundColor(viewed ? Color("TextSecondary") : Color("Accent"))
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: faq.icon)
                    .foregroundColor(viewed ? Color("TextSecondary") : Color("Accent"))
                    .frame(width: 20, height: 20)
            }

            Text(faq.question)
                .foregroundColor(viewed ? Color("TextSecondary") : Color("Accent"))
                .font(.system(size: 16))
            Spacer()
            Image(systemName: expanded ? "chevron.down" : "chevron.right")
                .foregroundColor(Color("TextSecondary"))
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct FAQView: View {
    @State private var selected: FAQItem?

    @StateObject private var state = AppState.shared

    let faqs: [FAQItem]
    let onFinish: (() -> Void)?

    var body: some View {
        NavigationStack {
            ZStack {
                DarkGradientView()
                    .ignoresSafeArea()

                List {
                    Section(header:
                        Text(FAQTitle)
                            .font(.title3.bold())
                            .foregroundColor(Color("TextReversed"))
                            .padding([.top, .bottom])
                    ) {
                        ForEach(faqs) { faq in
                            Button {
                                toggle(faq)
                            } label: {
                                FAQRow(
                                    faq: faq,
                                    viewed: state.viewedFAQIDs.contains(faq.id),
                                    expanded: selected == faq
                                )
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color("FieldBackground"))
                        }
                    }

                    Section {
                        Button(FAQContinueButtonLabel) {
                            (onFinish ?? { state.onboardingStep = .auth })()
                        }
                        .buttonStyle(CapsuleButtonStyle())
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .sheet(item: $selected) { faq in
                    FAQSheet(faq: faq) {
                        selected = nil
                    }
                    .presentationDetents([.fraction(0.6), .medium, .large])
                    .presentationDragIndicator(.visible)
                    .environmentObject(state)
                }
            }
        }
    }

    private func toggle(_ faq: FAQItem) {
        if selected == faq {
            selected = nil
        } else {
            if !state.viewedFAQIDs.contains(faq.id) {
                state.viewedFAQIDs.insert(faq.id)
                Task { await FirebaseService.shared.markFAQViewed(faq.id) }
            }
            selected = faq
        }
    }

    private var FAQTitle: LocalizedStringKey {
        onFinish == nil ? "A few quick things before we start..." : "Common questions:"
    }

    private var FAQContinueButtonLabel: LocalizedStringKey {
        onFinish == nil ? "Continue" : "Close"
    }
}

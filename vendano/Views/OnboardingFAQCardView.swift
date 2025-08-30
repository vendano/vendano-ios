//
//  OnboardingFAQCardView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/21/25.
//

import SwiftUI

struct OnboardingFAQCardView: View {
    @EnvironmentObject var theme: VendanoTheme
    @State private var currentIndex: Int = 0
    @State private var level: Int = 0 // 0 = answer, 1 = clarify, 2 = details
    let faqs: [FAQItem]
    let onSkip: (() -> Void)?
    @StateObject private var state = AppState.shared

    private var faq: FAQItem { faqs[currentIndex] }
    private var viewed: Bool { state.viewedFAQIDs.contains(faq.id) }

    private var promptText: String {
        switch level {
        case 0: return "Tap for clarity"
        case 1: return "Tap for details"
        default: return "Tap for summary"
        }
    }

    var body: some View {
        ZStack {
            LightGradientView()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                TabView(selection: $currentIndex) {
                    ForEach(faqs.indices, id: \.self) { idx in
                        pageView(for: faqs[idx])
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentIndex)
                .onChange(of: currentIndex) { _, newIndex in
                    let item = faqs[newIndex]
                    if !state.viewedFAQIDs.contains(item.id) {
                        state.viewedFAQIDs.insert(item.id)
                        Task { await FirebaseService.shared.markFAQViewed(item.id) }
                    }
                    level = 0
                }

                Button("Skip", action: onSkip ?? { state.onboardingStep = .auth })
                    .buttonStyle(.borderedProminent)
                    .tint(theme.color(named: "Accent"))

                Text("(or swipe for more)")
                    .vendanoFont(.caption, size: 13)
                    .foregroundColor(theme.color(named: "TextSecondary"))
            }
            .padding()
            .onAppear {
                level = 0
                
                let item = faqs[currentIndex]
                if !state.viewedFAQIDs.contains(item.id) {
                    state.viewedFAQIDs.insert(item.id)
                    Task { await FirebaseService.shared.markFAQViewed(item.id) }
                }
            }
        }
    }

    @ViewBuilder
    private func pageView(for item: FAQItem) -> some View {
        let isViewed = state.viewedFAQIDs.contains(item.id)
        VStack(spacing: 24) {
            // navigation arrows + tappable card
            HStack {
                arrowButton(direction: -1)
                Spacer()
                Button(action: toggleLevel) {
                    card(for: item, viewed: isViewed)
                }
                Spacer()
                arrowButton(direction: 1)
            }
            .padding(.horizontal)

            // question and answer/clarify/details
            Button(action: toggleLevel) {
                Text(item.question)
                    .vendanoFont(.title, size: 24, weight: .semibold)
                    .foregroundColor(theme.color(named: "TextPrimary"))
                    .multilineTextAlignment(.center)
            }
            Button(action: toggleLevel) {
                Text(level == 0 ? item.answer : (level == 1 ? item.clarify : item.details))
                    .vendanoFont(.body, size: 16)
                    .foregroundColor(theme.color(named: "TextSecondary"))
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
            }

            // tap prompt
            Button(action: toggleLevel) {
                Text(promptText)
                    .vendanoFont(.body, size: 14, weight: .semibold)
                    .foregroundColor(theme.color(named: "Accent"))
            }
        }
    }

    // MARK: – Components

    private func card(for faq: FAQItem, viewed: Bool) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(viewed ? theme.color(named: "TextSecondary") : theme.color(named: "Accent"))
            .frame(width: 120, height: 120)
            .overlay(
                Group {
                    if faq.icon.count == 1 {
                        Text(faq.icon)
                            .font(.system(size: 48))
                            .foregroundColor(theme.color(named: "TextReversed"))
                    } else {
                        Image(systemName: faq.icon)
                            .font(.system(size: 48))
                            .foregroundColor(theme.color(named: "TextReversed"))
                    }
                }
            )
    }

    private func arrowButton(direction: Int) -> some View {
        Button {
            withAnimation {
                changeIndex(by: direction)
            }
        } label: {
            Image(systemName: direction < 0 ? "chevron.left" : "chevron.right")
                .font(.largeTitle)
                .foregroundColor(viewed ? theme.color(named: "TextSecondary") : theme.color(named: "Accent"))
        }
        .buttonStyle(.plain)
        .padding(8)
        .contentShape(Circle())
    }

    // MARK: – Logic

    private func changeIndex(by offset: Int) {
        // mark current viewed on first leave
        if !viewed {
            state.viewedFAQIDs.insert(faq.id)
            Task { await FirebaseService.shared.markFAQViewed(faq.id) }
        }
        let count = faqs.count
        currentIndex = (currentIndex + offset + count) % count
        level = 0
    }

    private func toggleLevel() {
        level = (level + 1) % 3
    }
}

// MARK: – Preview

// struct OnboardingFAQCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        OnboardingFAQCardView(
//            faqs: FAQs.shared.onboarding,
//            onSkip: {}
//        )
//        .preferredColorScheme(.dark)
//    }
// }

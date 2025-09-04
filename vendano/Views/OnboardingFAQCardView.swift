//
//  OnboardingFAQCardView.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/21/25.

import SwiftUI

struct OnboardingFAQCardView: View {
    @EnvironmentObject var theme: VendanoTheme

    @State private var currentIndex: Int = 0
    @State private var level: Int = 0 // 0 = answer, 1 = clarify, 2 = details
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging: Bool = false

    // Local-only "viewed" tracking for this onboarding screen
    @State private var locallyViewed = Set<FAQItem.ID>()

    let faqs: [FAQItem]
    let onSkip: (() -> Void)?
    @StateObject private var state = AppState.shared

    private var hasFAQs: Bool { !faqs.isEmpty }

    private var promptText: String {
        switch level {
        case 0: return "Tap for clarity"
        case 1: return "Tap for details"
        default: return "Tap for summary"
        }
    }

    var body: some View {
        ZStack {
            LightGradientView().ignoresSafeArea()

            if hasFAQs {
                VStack(spacing: 20) {
                    Spacer(minLength: 0)

                    // ---- Pager container (measure AFTER padding, and clip) ----
                    GeometryReader { proxy in
                        let pageWidth = max(1, proxy.size.width)

                        // Build once to reuse in both .gesture paths
                        let drag = DragGesture(minimumDistance: 12, coordinateSpace: .local)
                            .updating($isDragging) { _, s, _ in s = true }
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                let threshold = pageWidth * 0.22
                                let translation = value.translation.width
                                let count = faqs.count

                                var newIndex = currentIndex
                                if translation <= -threshold {
                                    newIndex = min(currentIndex + 1, count - 1)
                                } else if translation >= threshold {
                                    newIndex = max(currentIndex - 1, 0)
                                }
                                dragOffset = 0
                                if newIndex != currentIndex {
                                    withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.9, blendDuration: 0.2)) {
                                        currentIndex = newIndex
                                        level = 0
                                    }
                                }
                            }

                        ZStack {
                            HStack(spacing: 0) {
                                ForEach(Array(faqs.enumerated()), id: \.offset) { _, item in
                                    pageView(for: item)
                                        .frame(width: pageWidth)
                                }
                            }
                            .offset(x: -CGFloat(currentIndex) * pageWidth + dragOffset)
                            .animation(.interactiveSpring(response: 0.32, dampingFraction: 0.9, blendDuration: 0.2), value: currentIndex)
                            .animation(nil, value: dragOffset)
                        }
                        .clipped()                        // avoid showing blank gutters
                        .contentShape(Rectangle())        // full-rect hit area
                        .highPriorityGesture(drag, including: .all) // swipe works anywhere, even over buttons
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 24) // width measured AFTER this padding

                    Spacer(minLength: 0)

                    Button("Skip", action: onSkip ?? { state.onboardingStep = .auth })
                        .buttonStyle(.borderedProminent)
                        .tint(theme.color(named: "Accent"))

                    Text("(or swipe for more)")
                        .vendanoFont(.caption, size: 13)
                        .foregroundColor(theme.color(named: "TextSecondary"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .onAppear {
                    level = 0
                    locallyViewed.removeAll()   // start fresh; do not gray initial card
                    clampIndexToBounds()
                }
                .onChange(of: faqs.count) { _, _ in
                    clampIndexToBounds()
                }
                .onChange(of: currentIndex) { oldIndex, newIndex in
                    guard faqs.indices.contains(oldIndex) else { return }
                    let item = faqs[oldIndex]
                    locallyViewed.insert(item.id)
                }
            } else {
                Text("No FAQs available.")
                    .vendanoFont(.body, size: 16)
                    .foregroundColor(theme.color(named: "TextPrimary"))
                    .padding()
            }
        }
    }

    // MARK: – Page Content

    @ViewBuilder
    private func pageView(for item: FAQItem) -> some View {
        let isViewed = locallyViewed.contains(item.id)
        VStack(spacing: 24) {
            // navigation arrows + tappable card
            HStack {
                arrowButton(direction: -1, currentViewed: isViewed)
                Spacer()
                Button(action: toggleLevel) {
                    card(for: item, viewed: isViewed)
                }
                Spacer()
                arrowButton(direction: 1, currentViewed: isViewed)
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
            .padding()

            // tap prompt
            Button(action: toggleLevel) {
                Text(promptText)
                    .vendanoFont(.body, size: 14, weight: .semibold)
                    .foregroundColor(theme.color(named: "Accent"))
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
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

    private func arrowButton(direction: Int, currentViewed: Bool) -> some View {
        Button {
            let count = faqs.count
            guard count > 0 else { return }
            let target = (currentIndex + direction + count) % count // wrap
            withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.9, blendDuration: 0.2)) {
                currentIndex = target
                level = 0
            }
            // marking 'viewed' happens in onChange(currentIndex)
        } label: {
            Image(systemName: direction < 0 ? "chevron.left" : "chevron.right")
                .font(.largeTitle)
                .foregroundColor(currentViewed ? theme.color(named: "TextSecondary") : theme.color(named: "Accent"))
        }
        .buttonStyle(.plain)
        .padding(8)
        .contentShape(Circle())
    }

    // MARK: – Logic

    private func clampIndexToBounds() {
        guard !faqs.isEmpty else {
            currentIndex = 0
            return
        }
        currentIndex = min(max(currentIndex, 0), faqs.count - 1)
    }

    private func toggleLevel() {
        level = (level + 1) % 3
    }
}

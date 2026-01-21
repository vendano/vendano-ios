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

    // We keep dragOffset as State so we can animate it to 0 on release.
    @State private var dragOffset: CGFloat = 0
    @GestureState private var isDragging: Bool = false

    // Local-only "viewed" tracking for this onboarding screen
    @State private var locallyViewed = Set<FAQItem.ID>()
    
    @State private var viewedMarkWorkItem: DispatchWorkItem?
    private let viewedMarkDelay: TimeInterval = 0.34

    let faqs: [FAQItem]?
    let onSkip: (() -> Void)?
    @StateObject private var state = AppState.shared

    private var hasFAQs: Bool { !(faqs?.isEmpty ?? false) }

    private var promptText: String {
        switch level {
        case 0: return L10n.OnboardingFAQCardView.tapForClarity
        case 1: return L10n.OnboardingFAQCardView.tapForDetails
        default: return L10n.OnboardingFAQCardView.tapForSummary
        }
    }

    var body: some View {
        ZStack {
            LightGradientView().ignoresSafeArea()

            if hasFAQs, let faqs {
                VStack(spacing: 20) {
                    Spacer(minLength: 0)

                    GeometryReader { proxy in
                        let pageSize = proxy.size
                        let pageWidth = max(1, pageSize.width)

                        let drag = DragGesture(minimumDistance: 12, coordinateSpace: .local)
                            .updating($isDragging) { _, s, _ in s = true }
                            .onChanged { value in
                                // IMPORTANT: update dragOffset with animations disabled so it tracks the finger perfectly.
                                var t = value.translation.width
                                t = applyEdgeResistance(translation: t, count: faqs.count)

                                var tx = Transaction()
                                tx.animation = nil
                                withTransaction(tx) {
                                    dragOffset = t
                                }
                            }
                            .onEnded { value in
                                let threshold = pageWidth * 0.22
                                let translation = applyEdgeResistance(translation: value.translation.width, count: faqs.count)

                                let newIndex: Int
                                if translation <= -threshold {
                                    newIndex = min(currentIndex + 1, faqs.count - 1)
                                } else if translation >= threshold {
                                    newIndex = max(currentIndex - 1, 0)
                                } else {
                                    newIndex = currentIndex
                                }

                                // IMPORTANT: animate BOTH snap-back (dragOffset -> 0) and page change together.
                                withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.9, blendDuration: 0.2)) {
                                    dragOffset = 0
                                    if newIndex != currentIndex {
                                        currentIndex = newIndex
                                        level = 0
                                    }
                                }
                            }

                        HStack(spacing: 0) {
                            ForEach(Array(faqs.enumerated()), id: \.element.id) { _, item in
                                pageView(for: item, pageSize: pageSize)
                                    .frame(width: pageWidth, height: pageSize.height)
                            }
                        }
                        .offset(x: -CGFloat(currentIndex) * pageWidth + dragOffset)
                        .clipped()
                        .contentShape(Rectangle())
                        .highPriorityGesture(drag, including: .all)
                        .animation(.interactiveSpring(response: 0.32, dampingFraction: 0.9, blendDuration: 0.2), value: currentIndex)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 0)

                    Button(L10n.Common.skip, action: onSkip ?? { state.onboardingStep = .auth })
                        .buttonStyle(.borderedProminent)
                        .tint(theme.color(named: "Accent"))

                    Text(L10n.OnboardingFAQCardView.orSwipeForMore)
                        .vendanoFont(.caption, size: 13)
                        .foregroundColor(theme.color(named: "TextSecondary"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .onAppear {
                    level = 0
                    locallyViewed.removeAll() // start fresh; do not gray initial card
                    clampIndexToBounds()
                }
                .onChange(of: faqs.count) { _, _ in
                    clampIndexToBounds()
                }
                .onChange(of: currentIndex) { oldIndex, _ in
                    guard faqs.indices.contains(oldIndex) else { return }

                    // Cancel any pending mark if the user swipes again quickly
                    viewedMarkWorkItem?.cancel()

                    let item = faqs[oldIndex]
                    let work = DispatchWorkItem {
                        locallyViewed.insert(item.id)
                    }
                    viewedMarkWorkItem = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + viewedMarkDelay, execute: work)
                }

            } else {
                Text(L10n.OnboardingFAQCardView.noFaqsAvailable)
                    .vendanoFont(.body, size: 16)
                    .foregroundColor(theme.color(named: "TextPrimary"))
                    .padding()
            }
        }
    }

    // MARK: – Page Content

    private func pageView(for item: FAQItem, pageSize: CGSize) -> some View {
        let isViewed = locallyViewed.contains(item.id)
        
        let topInset = clamp(pageSize.height * 0.06, min: 16, max: 52)
        let bottomInset = clamp(pageSize.height * 0.04, min: 12, max: 44)

        // Keep header + body area stable so chevrons don't shift when text changes.
        let headerHeight: CGFloat = 160
        let questionMinHeight: CGFloat = 56

        // Fixed body height: enough room, but doesn't grow/shrink with content.
        // Tune these if you want it tighter/looser.
        let bodyHeight = clamp(pageSize.height * 0.28, min: 160, max: 260)

        return VStack(spacing: 16) {
            Spacer(minLength: topInset)

            headerRow(item: item, isViewed: isViewed)
                .frame(height: headerHeight, alignment: .center)

            Text(item.question)
                .vendanoFont(.title, size: 24, weight: .semibold)
                .foregroundColor(theme.color(named: "TextPrimary"))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, minHeight: questionMinHeight, alignment: .center)
                .padding(.horizontal)

            ScrollView(showsIndicators: false) {
                Text(currentBodyText(for: item))
                    .vendanoFont(.body, size: 16)
                    .foregroundColor(theme.color(named: "TextSecondary"))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
            }
            .frame(height: bodyHeight)
            .contentShape(Rectangle())
            .onTapGesture { toggleLevel() }

            Text(promptText)
                .vendanoFont(.body, size: 14, weight: .semibold)
                .foregroundColor(theme.color(named: "Accent"))
                .padding(.top, 4)
                .contentShape(Rectangle())
                .onTapGesture { toggleLevel() }

            Spacer(minLength: bottomInset)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .contentShape(Rectangle())
        .onTapGesture { toggleLevel() }
    }

    private func headerRow(item: FAQItem, isViewed: Bool) -> some View {
        HStack {
            arrowButton(direction: -1, currentViewed: isViewed)

            Spacer()

            card(for: item, viewed: isViewed)
                .contentShape(Rectangle())
                .onTapGesture { toggleLevel() }

            Spacer()

            arrowButton(direction: 1, currentViewed: isViewed)
        }
        .padding(.horizontal)
    }

    private func currentBodyText(for item: FAQItem) -> String {
        switch level {
        case 0: return item.answer
        case 1: return item.clarify
        default: return item.details
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

    private func arrowButton(direction: Int, currentViewed: Bool) -> some View {
        Button {
            guard let faqs else { return }
            let count = faqs.count
            guard count > 0 else { return }

            // NOTE: This wraps. If you want swipe to also wrap, we can mirror that logic in the gesture.
            let target = (currentIndex + direction + count) % count

            withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.9, blendDuration: 0.2)) {
                currentIndex = target
                level = 0
                dragOffset = 0
            }
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
        guard hasFAQs, let faqs else {
            currentIndex = 0
            return
        }
        currentIndex = min(max(currentIndex, 0), faqs.count - 1)
    }

    private func toggleLevel() {
        level = (level + 1) % 3
    }

    // Edge resistance to avoid harsh stops at ends when swiping.
    private func applyEdgeResistance(translation: CGFloat, count: Int) -> CGFloat {
        guard count > 0 else { return translation }

        let atFirst = currentIndex == 0
        let atLast = currentIndex == count - 1

        if (atFirst && translation > 0) || (atLast && translation < 0) {
            return translation * 0.35
        }
        return translation
    }

    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.max(min, Swift.min(max, value))
    }
}

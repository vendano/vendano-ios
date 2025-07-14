//
//  AvatarThumb.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/7/25.
//

import SwiftUI

struct AvatarThumb: View {
    @EnvironmentObject var theme: VendanoTheme
    let localImage: Image?
    let url: URL?
    let name: String?
    let size: CGFloat
    let tap: () -> Void

    private let placeholder = Image(systemName: "person.crop.circle.fill")

    private var contentSize: CGFloat {
        size * 0.4
    }

    var body: some View {
        ZStack {
            // Accent background base
            Circle().fill(theme.color(named: "Accent"))

            // Avatar image: local or async
            avatarImage
        }
        .frame(width: size, height: size)
        .mask {
            if VendanoTheme.shared.isHosky() {
                Image("hosky-mask")
                    .resizable()
                    .scaledToFit()
            } else {
                Circle()
            }
        }
        .contentShape(Circle()) // still use circle for tappable region
        .onTapGesture(perform: tap)
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let local = localImage {
            local
                .resizable()
                .scaledToFill()
        } else if let url = url {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(img):
                    img.resizable().scaledToFill()
                default:
                    fallbackView
                }
            }
            .id(url)
        } else {
            fallbackView
        }
    }

    @ViewBuilder
    private var fallbackView: some View {
        if let first = name?.first {
            Text(String(first))
                .vendanoFont(.title, size: contentSize, weight: .semibold)
                .foregroundColor(theme.color(named: "TextReversed"))
        } else {
            placeholder
                .resizable()
                .scaledToFill()
                .frame(width: contentSize, height: contentSize)
                .foregroundColor(theme.color(named: "TextReversed"))
        }
    }

    @ViewBuilder
    private var maskView: some View {
        if VendanoTheme.shared.isHosky() {
            Image("hosky-mask")
                .resizable()
                .scaledToFit()
        } else {
            Circle()
        }
    }

}

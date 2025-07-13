//
//  AvatarThumb.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/7/25.
//

import SwiftUI

struct AvatarThumb: View {
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
            // Always draw the accent circle behind everything:
            Circle().fill(Color("Accent"))

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
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.secondary, lineWidth: 1))
        .contentShape(Circle())
        .onTapGesture(perform: tap)
    }

    @ViewBuilder
    private var fallbackView: some View {
        if let first = name?.first {
            Text(String(first))
                .font(.system(size: contentSize, weight: .semibold))
                .foregroundColor(Color("TextReversed"))
        } else {
            placeholder
                .resizable()
                .scaledToFill()
                .frame(width: contentSize, height: contentSize)
                .foregroundColor(Color("TextReversed"))
        }
    }
}

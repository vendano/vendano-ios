//
//  FeedbackMessage.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/9/25.
//

import Foundation

struct FeedbackMessage: Identifiable, Equatable {
    let id: String
    let uid: String
    let text: String
    let timestamp: Date
    let fromDeveloper: Bool
}

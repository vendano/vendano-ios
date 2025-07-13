//
//  TxRowViewModel.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/26/25.
//

import Foundation

struct TxRowViewModel: Identifiable {
    let id: String
    let date: Date
    let outgoing: Bool
    let amount: Double
    let counterpartyAddress: String
    var name: String?
    var avatarURL: URL?
    var balanceAfter: Double
}

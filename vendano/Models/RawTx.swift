//
//  RawTx.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/26/25.
//

import Foundation

struct RawTx {
    let hash: String
    let date: Date
    let blockHeight: Int
    let inputs: [(address: String, amount: UInt64)]
    let outputs: [(address: String, amount: UInt64)]

    func isOutgoing(for wallet: String) -> Bool {
        let inSum = inputs.filter { $0.address == wallet }.map(\.amount).reduce(0, +)
        let outSum = outputs.filter { $0.address == wallet }.map(\.amount).reduce(0, +)
        return (Int64(inSum) - Int64(outSum)) < 0
    }
}

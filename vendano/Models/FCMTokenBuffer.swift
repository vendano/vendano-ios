//
//  FCMTokenBuffer.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 9/4/25.
//

import FirebaseAuth
import FirebaseFirestore

final class FCMTokenBuffer {
    static let shared = FCMTokenBuffer()
    private init() {}

    var pendingToken: String?

    func flushIfPossible() {
        guard let token = pendingToken,
              let uid = Auth.auth().currentUser?.uid else { return }

        Task {
            await FirebaseService.shared.setUserData(uid: uid, data: ["fcmToken": token])
        }
        pendingToken = nil
    }
}

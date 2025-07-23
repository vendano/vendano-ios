//
//  FeedbackViewModel.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/9/25.
//

import FirebaseFirestore
import SwiftUI

@MainActor
class FeedbackViewModel: ObservableObject {
    @Published var messages: [FeedbackMessage] = []

    private var listener: ListenerRegistration?

    init() {
        if let uid = FirebaseService.shared.user?.uid {
            listener = Firestore
                .firestore()
                .collection("users")
                .document(uid)
                .collection("feedback")
                .order(by: "timestamp", descending: true)
                .addSnapshotListener { snap, _ in
                    guard let docs = snap?.documents else { return }
                    self.messages = docs.compactMap { d in
                        let data = d.data()
                        guard
                            let text = data["text"] as? String,
                            let ts = (data["timestamp"] as? Timestamp)?.dateValue()
                        else { return nil }

                        let fromDev = data["fromDeveloper"] as? Bool ?? false
                        return FeedbackMessage(
                            id: d.documentID,
                            uid: uid,
                            text: text,
                            timestamp: ts,
                            fromDeveloper: fromDev
                        )
                    }
                }
        } else {
            listener = nil
        }
    }

    func send(_ text: String) {
        guard let uid = FirebaseService.shared.user?.uid else { return }
        let ref = Firestore
            .firestore()
            .collection("users")
            .document(uid)
            .collection("feedback")
            .document() // auto ID
        ref.setData([
            "uid": uid,
            "text": text,
            "timestamp": FieldValue.serverTimestamp(),
        ])
    }

    deinit { listener?.remove() }
}

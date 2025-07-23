//
//  FirebaseService.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/3/25.
//

import CryptoKit
import FirebaseAuth
@preconcurrency import FirebaseFirestore
import FirebaseStorage
import SwiftUI

enum FirebaseServiceError: Error {
    case userNotSignedIn
    case pngEncodingFailed
    case unknown
}

@MainActor
final class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    @Published private(set) var user: User?

    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    private var listener: ListenerRegistration?

    private init() { listenAuth() }

    enum RemoveHandleError: LocalizedError {
        case notSignedIn
        case onlyProvider
        case handleNotFound
        var errorDescription: String? {
            switch self {
            case .notSignedIn: return "No signed-in user."
            case .onlyProvider: return "Cannot remove the only sign-in method. Add another before removing."
            case .handleNotFound: return "Handle not found in profile."
            }
        }
    }

    // MARK: – Auth listener

    private func listenAuth() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, usr in
            guard let self else { return }
            self.user = usr
            self.listener?.remove()
            guard let uid = usr?.uid else { return }

            Task {
                await self.fetchPublicState(uid: uid)
                await self.fetchPrivateState(uid: uid)
            }
        }
    }

    private func fetchPublicState(uid: String) async {
        do {
            let snap = try await db.collection("public").document(uid).getDocument()
            guard let d = snap.data() else { return }
            let state = AppState.shared
            DispatchQueue.main.async {
                state.displayName = d["displayName"] as? String ?? ""
                state.avatarUrl = d["avatarURL"] as? String
                state.walletAddress = d["walletAddress"] as? String ?? ""
            }
        } catch {
            DebugLogger.log("❌ fetchPublicState: \(error)")
        }
    }

    private func fetchPrivateState(uid: String) async {
        do {
            let snap = try await db.collection("users").document(uid).getDocument()
            guard let d = snap.data() else { return }
            let state = AppState.shared
            DispatchQueue.main.async {
                state.phone = d["phone"] as? [String] ?? []
                state.email = d["email"] as? [String] ?? []
                let faqs = d["viewedFAQ"] as? [String] ?? []
                state.viewedFAQIDs = Set(faqs.compactMap(UUID.init))
            }
        } catch {
            DebugLogger.log("❌ fetchPrivateState: \(error)")
        }
    }

    // MARK: – Phone OTP

    func sendPhoneOTP(e164: String, completion: @escaping () -> Void) {
        UserDefaults.standard.set(e164, forKey: "PhoneForSignIn")

        PhoneAuthProvider.provider().verifyPhoneNumber(e164, uiDelegate: nil) { id, err in
            if let err = err as NSError? {
                DebugLogger.log("❌ [PHONE OTP] verifyPhoneNumber error: \(err)\nUserInfo: \(err.userInfo)")
                return
            }
            guard let id = id else {
                DebugLogger.log("❌ [PHONE OTP] verificationID is nil!")
                return
            }
            UserDefaults.standard.set(id, forKey: "phoneVID")
            UserDefaults.standard.set(e164, forKey: "phoneNumber")
            completion()
        }
    }

    func confirmPhoneOTP(code: String, completion: @escaping (String?) -> Void) {
        guard let id = UserDefaults.standard.string(forKey: "phoneVID"),
              let phone = UserDefaults.standard.string(forKey: "phoneNumber")
        else {
            DebugLogger.log("❌ [CONFIRM OTP] Missing phoneVID in UserDefaults!")
            return
        }

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: id,
            verificationCode: code
        )

        if let user = Auth.auth().currentUser {
            // Already signed in by email? Link phone credential to that user
            user.link(with: credential) { _, error in
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    Task {
                        do {
                            try await self.savePhone(phone)
                        }
                    }
                    completion(nil)
                }
            }
        } else {
            Auth.auth().signIn(with: credential) { authResult, error in
                if let err = error as NSError? {
                    DebugLogger.log("❌ [CONFIRM OTP] signIn error: \(err)\nUserInfo:\(err.userInfo)")
                    completion(err.localizedDescription)
                } else {
                    self.user = authResult?.user

                    Task {
                        do {
                            await self.markAllFAQsViewed()
                            try await self.savePhone(phone)
                        }
                    }

                    completion(nil)
                }
            }
        }
    }

    func savePhone(_ phone: String) async throws {
        guard let uid = user?.uid else { throw FirebaseServiceError.userNotSignedIn }

        let userRef = db.collection("users").document(uid)
        let publicRef = db.collection("public").document(uid)

        let normalized = normalizePhone(phone)
        let hash = handleHash(normalized)

        async let uSnap = userRef.getDocument()
        async let pSnap = publicRef.getDocument()
        let (userDoc, publicDoc) = try await (uSnap, pSnap)

        let userHasCreated = userDoc.exists && userDoc.data()?["createdDate"] != nil
        let publicHasCreated = publicDoc.exists && publicDoc.data()?["createdDate"] != nil

        let userBase: [String: Any] = [
            "phone": FieldValue.arrayUnion([phone]),
            "updatedDate": FieldValue.serverTimestamp(),
        ]
        let publicBase: [String: Any] = [
            "phoneHashes": FieldValue.arrayUnion([hash]),
            "updatedDate": FieldValue.serverTimestamp(),
        ]

        if userHasCreated {
            try await userRef.updateData(userBase)
        } else {
            var full = userBase
            full["createdDate"] = FieldValue.serverTimestamp()
            try await userRef.setData(full, merge: true)
        }

        AppState.shared.phone.append(phone)

        if publicHasCreated {
            try await publicRef.updateData(publicBase)
        } else {
            var full = publicBase
            full["createdDate"] = FieldValue.serverTimestamp()
            try await publicRef.setData(full, merge: true)
        }
    }

    // MARK: – Email link (OTP-ish) auth

    func sendEmailLink(to email: String, completion: @escaping (Error?) -> Void) {
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.handleCodeInApp = true

        // ✏️ Embed the address as a query-param instead of relying on UserDefaults
        var comps = URLComponents(string: "https://signin.vendano.net")!
        comps.queryItems = [URLQueryItem(name: "email", value: email)]
        actionCodeSettings.url = comps.url!

        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)

        Auth.auth().sendSignInLink(toEmail: email,
                                   actionCodeSettings: actionCodeSettings)
        { err in
            completion(err)
        }
    }

    func confirmEmailLink(link: String, email: String) async throws {
        let cred = EmailAuthProvider.credential(withEmail: email, link: link)

        if let me = Auth.auth().currentUser {
            // link to existing
            do {
                try await me.link(with: cred)
            } catch let err as NSError {
                // ignore if it's already linked
                if AuthErrorCode(rawValue: err.code) != .providerAlreadyLinked {
                    throw err
                }
            }
        } else {
            // brand-new sign-in
            let result = try await Auth.auth().signIn(withEmail: email, link: link)
            user = result.user
            await markAllFAQsViewed()
        }

        try await saveEmail(email)
    }

    func saveEmail(_ email: String) async throws {
        guard let uid = user?.uid else { throw FirebaseServiceError.userNotSignedIn }

        let norm = email.lowercased()
        let hash = handleHash(norm)

        let userRef = db.collection("users").document(uid)
        let publicRef = db.collection("public").document(uid)

        async let userSnap = userRef.getDocument()
        async let publicSnap = publicRef.getDocument()

        let (uSnap, pSnap) = try await (userSnap, publicSnap)
        let userHasCreated = uSnap.exists && uSnap.data()?["createdDate"] != nil
        let publicHasCreated = pSnap.exists && pSnap.data()?["createdDate"] != nil

        let userBase: [String: Any] = [
            "email": FieldValue.arrayUnion([email]),
            "updatedDate": FieldValue.serverTimestamp(),
        ]
        let publicBase: [String: Any] = [
            "emailHashes": FieldValue.arrayUnion([hash]),
            "updatedDate": FieldValue.serverTimestamp(),
        ]

        if userHasCreated {
            try await userRef.updateData(userBase)
        } else {
            var full = userBase
            full["createdDate"] = FieldValue.serverTimestamp()
            try await userRef.setData(full, merge: true)
        }

        AppState.shared.email.append(email)

        if publicHasCreated {
            try await safeUpdate(publicRef, [
                "emailHashes": FieldValue.arrayUnion([hash]),
                "updatedDate": FieldValue.serverTimestamp(),
            ])
        } else {
            var full = publicBase
            full["createdDate"] = FieldValue.serverTimestamp()
            try await publicRef.setData(full, merge: true)
        }
    }

    // MARK: – Profile update

    func saveAddress(_ addr: String) async throws {
        guard let uid = user?.uid else { return }
        try await db.collection("public").document(uid)
            .setData(["walletAddress": addr], merge: true)
    }

    func updateDisplayName(_ name: String) async throws {
        guard let uid = user?.uid else { return }
        try await db.collection("public").document(uid).setData([
            "displayName": name,
            "updatedDate": FieldValue.serverTimestamp(),
        ], merge: true)
    }

    func uploadAvatar(from url: URL) async throws -> URL {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw FirebaseServiceError.pngEncodingFailed
        }
        // Reuse existing image-cropping + upload logic
        let newURL = try await uploadAvatar(image)

        // Update in-memory state
        DispatchQueue.main.async {
            AppState.shared.avatar = Image(uiImage: image)
            AppState.shared.avatarUrl = newURL.absoluteString
        }
        return newURL
    }

    func uploadAvatar(_ image: UIImage) async throws -> URL {
        guard let uid = user?.uid else {
            throw FirebaseServiceError.userNotSignedIn
        }

        let side = min(image.size.width, image.size.height)
        let rect = CGRect(
            x: (image.size.width - side) / 2,
            y: (image.size.height - side) / 2,
            width: side,
            height: side
        )
        guard let cg = image.cgImage?.cropping(to: rect) else {
            throw URLError(.cannotDecodeContentData)
        }
        let square = UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)

        let thumb = square.resize(to: 200)
        guard let thumbData = thumb.jpegData(compressionQuality: 0.8) else {
            throw FirebaseServiceError.pngEncodingFailed
        }

        let thumbPath = "avatars/\(uid)/avatar_thumb.png"
        _ = try await storage.child(thumbPath).putDataAsync(thumbData)

        let url = try await storage.child(thumbPath).downloadURL()

        try await db.collection("public").document(uid).setData([
            "avatarURL": url.absoluteString,
            "updatedDate": FieldValue.serverTimestamp(),
        ], merge: true)

        return url
    }

    func fetchThumbData(maxSize: Int64 = 500 * 500) async throws -> Data {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirebaseServiceError.userNotSignedIn
        }
        let path = "avatars/\(uid)/avatar_thumb.png"
        let ref = storage.child(path)

        return try await withCheckedThrowingContinuation { continuation in
            ref.getData(maxSize: maxSize) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: FirebaseServiceError.unknown)
                }
            }
        }
    }

    func deleteAvatarFolder(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(FirebaseServiceError.userNotSignedIn))
            return
        }
        let folderRef = storage.child("avatars/\(uid)")
        // List all items under this prefix
        folderRef.listAll { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let items = result?.items else {
                // nothing to delete
                completion(.success(()))
                return
            }
            let group = DispatchGroup()
            var firstError: Error?
            for itemRef in items {
                group.enter()
                itemRef.delete { err in
                    if let err = err {
                        DebugLogger.log("⚠️ Could not delete \(itemRef.fullPath): \(err.localizedDescription)")
                        if firstError == nil { firstError = err }
                    }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                if let error = firstError {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: – FAQ tracking

    func markAllFAQsViewed() async {
        guard let uid = user?.uid else { return }
        let faqViewedIDs: Set<UUID> = AppState.shared.viewedFAQIDs

        try? await db.collection("users").document(uid)
            .setData([
                "viewedFAQ": FieldValue.arrayUnion(faqViewedIDs.map(\.uuidString)),
            ], merge: true)
    }

    func markFAQViewed(_ id: UUID) async {
        guard let uid = user?.uid else { return }
        try? await db.collection("users").document(uid)
            .setData([
                "viewedFAQ": FieldValue.arrayUnion([id.uuidString]),
            ], merge: true)
    }

    // MARK: – Handle lookup (name / avatar / address)

    @MainActor
    func fetchRecipient(for handle: String) async -> (name: String, avatarURL: String?, address: String)? {
        let hash = handleHash(handle)
        let col = db.collection("public")
        let emailQ = col.whereField("emailHashes", arrayContains: hash)
        let phoneQ = col.whereField("phoneHashes", arrayContains: hash)
        let addrQ = col.whereField("walletAddress", isEqualTo: handle)

        for query in [emailQ, phoneQ, addrQ] {
            do {
                let snap = try await query.getDocuments()
                if let doc = snap.documents.first {
                    let data = doc.data()
                    guard let name = data["displayName"] as? String,
                          let address = data["walletAddress"] as? String
                    else { return nil }
                    let avatar = data["avatarURL"] as? String
                    return (name, avatar, address)
                }
            } catch {
                DebugLogger.log("⚠️ fetchRecipient query failed: \(error)")
                // continue to the next query
            }
        }

        return nil
    }

    @MainActor
    func removeEmail(_ emailToRemove: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw RemoveHandleError.notSignedIn
        }
        // 1. Check Auth providerData for this email
        if let entry = user.providerData.first(where: {
            $0.providerID == EmailAuthProviderID && $0.email?.lowercased() == emailToRemove.lowercased()
        }) {
            let providers = user.providerData.map(\.providerID)
            // If this is the only provider, block removal
            if providers.count <= 1 {
                throw RemoveHandleError.onlyProvider
            }
            // Unlink
            _ = try await user.unlink(fromProvider: entry.providerID)
            print("✅ Unlinked email in Auth: \(emailToRemove)")
        } else {
            DebugLogger.log("⚠️ Email not linked in Auth, skipping unlink: \(emailToRemove)")
        }

        // 2. Remove from Firestore
        guard let uid = user.uid as String? else { throw RemoveHandleError.notSignedIn }
        let userRef = db.collection("users").document(uid)
        let publicRef = db.collection("public").document(uid)
        let hash = handleHash(emailToRemove)

        // Remove from users/{uid}.email array
        do {
            try await safeUpdate(userRef, [
                "email": FieldValue.arrayRemove([emailToRemove]),
                "updatedDate": FieldValue.serverTimestamp(),
            ])
            print("✅ Removed email from users/\(uid)")
        } catch {
            DebugLogger.log("⚠️ Could not update users/\(uid) email array (maybe doc missing?): \(error)")
        }
        // Remove from public/{uid}.emailHashes array
        do {
            try await safeUpdate(publicRef, [
                "emailHashes": FieldValue.arrayRemove([hash]),
                "updatedDate": FieldValue.serverTimestamp(),
            ])
            print("✅ Removed email hash from public/\(uid)")
        } catch {
            DebugLogger.log("⚠️ Could not update public/\(uid) emailHashes array: \(error)")
        }
    }

    @MainActor
    func removePhone(_ phoneToRemove: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw RemoveHandleError.notSignedIn
        }
        // 1. Check Auth providerData for this phone
        if let entry = user.providerData.first(where: {
            $0.providerID == PhoneAuthProviderID && $0.phoneNumber == phoneToRemove
        }) {
            let providers = user.providerData.map(\.providerID)
            if providers.count <= 1 {
                throw RemoveHandleError.onlyProvider
            }
            _ = try await user.unlink(fromProvider: entry.providerID)
            print("✅ Unlinked phone in Auth: \(phoneToRemove)")
        } else {
            DebugLogger.log("⚠️ Phone not linked in Auth, skipping unlink: \(phoneToRemove)")
        }

        // 2. Remove from Firestore
        guard let uid = user.uid as String? else { throw RemoveHandleError.notSignedIn }
        let userRef = db.collection("users").document(uid)
        let publicRef = db.collection("public").document(uid)
        let hash = handleHash(phoneToRemove)

        do {
            try await safeUpdate(userRef, [
                "phone": FieldValue.arrayRemove([phoneToRemove]),
                "updatedDate": FieldValue.serverTimestamp(),
            ])
            print("✅ Removed phone from users/\(uid)")
        } catch {
            DebugLogger.log("⚠️ Could not update users/\(uid) phone array: \(error)")
        }
        do {
            try await safeUpdate(publicRef, [
                "phoneHashes": FieldValue.arrayRemove([hash]),
                "updatedDate": FieldValue.serverTimestamp(),
            ])
            print("✅ Removed phone hash from public/\(uid)")
        } catch {
            DebugLogger.log("⚠️ Could not update public/\(uid) phoneHashes array: \(error)")
        }
    }

    @MainActor
    func removeUserData() async {
        guard let uid = user?.uid else { return }
        let batch = db.batch()

        let feedbackCol = db.collection("users").document(uid).collection("feedback")
        do {
            let snap = try await feedbackCol.getDocuments()
            for doc in snap.documents {
                batch.deleteDocument(doc.reference)
            }

            let userRef = db.collection("users").document(uid)
            let publicRef = db.collection("public").document(uid)
            batch.deleteDocument(userRef)
            batch.deleteDocument(publicRef)

            try await batch.commit()
            print("✅ Firestore data wiped")
        } catch {
            DebugLogger.log("❌ Error wiping Firestore data: \(error)")
        }
    }

    func logoutUser() {
        Task {
            do {
                try await Auth.auth().currentUser?.delete()
            } catch {
                DebugLogger.log("❌ Failed to delete Auth user: \(error)")
            }

            do {
                try Auth.auth().signOut()
            } catch {
                DebugLogger.log("❌ Sign-out error: \(error)")
            }
        }
    }

    // MARK: – helpers

    private func handleHash(_ h: String) -> String {
        let digest = SHA256.hash(data: Data(h.lowercased().utf8))
        return Data(digest).base64EncodedString()
    }

    func getUserStatus() async throws -> OnboardingStep {
        guard let uid = Auth.auth().currentUser?.uid else {
            return .auth
        }

        let doc = try await db.collection("public").document(uid).getDocument()

        if !doc.exists ||
            doc["displayName"] == nil
        {
            return .profile
        }

        return .walletChoice
    }

    private func safeUpdate(
        _ ref: DocumentReference,
        _ fields: [String: Any]
    ) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            ref.updateData(fields) { error in
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: ())
                }
            }
        }
    }

    /*
     @MainActor
     func seedMockRecipients() async {
         let db = Firestore.firestore()

         // 20 sample names
         let names = [
             "Alice","Bob","Carol","Dave","Eve","Frank","Grace","Koyaanisquatsiuth","Ivan","Judy",
             "Mallory","Niaj","Oscar","Peggy","Ru","Sybil","Trent","Victor","Walter","Xavier"
         ]

         func randomCardanoAddress() -> String {
             // testnet bech32 prefix + 50 random base32 chars
             let charset = Array("abcdefghijklmnopqrstuvwxyz234567")
             let suffix = (0..<50).map { _ in charset.randomElement()! }
             return "addr_test1" + String(suffix)
         }

         for (i, name) in names.enumerated() {
             let address = randomCardanoAddress()
             let avatarURL = "https://i.pravatar.cc/150?img=\(i+1)"

             let email = "\(name.lowercased())@\(name.lowercased()).com"

             let hash = handleHash(email)

             let docData: [String:Any] = [
                 "displayName": name,
                 "avatarURL": avatarURL,
                 "walletAddress": address,
                 "emailHashes": [hash],
                 "createdDate": FieldValue.serverTimestamp(),
                 "updatedDate": FieldValue.serverTimestamp(),
             ]

             do {
                 try await db
                     .collection("public")
                     .document()
                     .setData(docData, merge: true)
                 print("✅ Seeded \(name) @ \(address)")
             } catch {
                 print("❌ Failed to seed \(name):", error)
             }
         }

         print("🎉 Done seeding mock recipients.")
     }
     */

    private func normalizePhone(_ raw: String) -> String {
        // remove +, spaces, punctuation, etc.
        return raw.filter(\.isWholeNumber)
    }

    @MainActor
    func addPendingContact(_ handle: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirebaseServiceError.userNotSignedIn
        }
        let userRef = db.collection("users").document(uid)

        let norm = handle.lowercased()
        let hash = handleHash(norm)

        try await safeUpdate(userRef, [
            "pendingContacts": FieldValue.arrayUnion([hash]),
            "updatedDate": FieldValue.serverTimestamp(),
        ])
    }
}

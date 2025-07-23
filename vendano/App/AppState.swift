//
//  AppState.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/7/25.
//

import PhotosUI
import SwiftUI
import UIKit

final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var onboardingStep: OnboardingStep = .splash

    @Published var seedWords: [String] = []

    @Published var avatar: Image?
    @Published var avatarUrl: String?
    @Published var displayName: String = ""
    @Published var otpEmail: String?
    @Published var otpPhone: String?
    @Published var phone: [String] = []
    @Published var email: [String] = []
    @Published var walletAddress: String = "" {
        didSet {
            Task {
                await WalletService.shared.clearCache()
            }
            Task { @MainActor in
                refreshOnChainData()
            }
        }
    }

    @Published var viewedFAQIDs: Set<UUID> = []
    @Published var adaBalance: Double = 0
    @Published var hoskyBalance: Double = 0
    @Published var recentTxs: [TxRowViewModel] = []

    @MainActor
    func refreshOnChainData() {
        Task {
            guard !walletAddress.isEmpty else { return }
            do {
                await WalletService.shared.loadPrice()
                let (ada, hosky) = try await WalletService.shared.getBalances(for: walletAddress)
                self.adaBalance = ada
                self.hoskyBalance = hosky

                guard ada > 0 else { return }

                let raws = try await WalletService.shared.fetchTransactions(for: walletAddress)

                let sortedByBlockAndTime = raws.sorted {
                    if $0.blockHeight == $1.blockHeight {
                        let aOutgoing = $0.isOutgoing(for: walletAddress)
                        let bOutgoing = $1.isOutgoing(for: walletAddress)
                        // incoming first, then outgoing
                        if aOutgoing == bOutgoing {
                            return $0.date < $1.date
                        } else {
                            return !aOutgoing && bOutgoing
                        }
                    } else {
                        return $0.blockHeight > $1.blockHeight
                    }
                }

                var running = ada
                var vms: [TxRowViewModel] = []

                for tx in sortedByBlockAndTime {
                    // how much _net_ moved (positive = incoming, negative = outgoing)
                    let inSum = tx.inputs.filter { $0.address == walletAddress }.map(\.amount).reduce(0, +)
                    let outSum = tx.outputs.filter { $0.address == walletAddress }.map(\.amount).reduce(0, +)
                    let netLovelace = Int64(inSum) - Int64(outSum)
                    let netAda = Double(netLovelace) / 1_000_000

                    // apply net change to running balance
                    let balanceAfter = running
                    running += netAda

                    // pick the “other” party
                    let peers: [String]
                    if netAda < 0 {
                        // outgoing: look at all the outputs not equal to you
                        peers = tx.outputs.map(\.address).filter { $0 != walletAddress }
                    } else {
                        // incoming: look at all the inputs not equal to you
                        peers = tx.inputs.map(\.address).filter { $0 != walletAddress }
                    }

                    let outTx = tx.outputs.first?.address
                    let inTx = tx.inputs.first?.address

                    let counterparty = peers.first
                        ?? (netAda < 0
                            ? (outTx != walletAddress ? outTx : inTx)
                            : (inTx != walletAddress ? inTx : outTx))
                        ?? "Unknown"

                    vms.append(.init(
                        id: tx.hash,
                        date: tx.date,
                        outgoing: netAda < 0,
                        amount: abs(netAda),
                        counterpartyAddress: counterparty,
                        name: nil,
                        avatarURL: nil,
                        balanceAfter: balanceAfter
                    ))
                }

                await withTaskGroup(of: Void.self) { group in
                    for idx in vms.indices {
                        group.addTask {
                            if let (n, a, _) = await FirebaseService.shared
                                .fetchRecipient(for: vms[idx].counterpartyAddress)
                            {
                                vms[idx].name = n
                                vms[idx].avatarURL = a.flatMap(URL.init(string:))
                            }
                        }
                    }
                    await group.waitForAll()
                }

                for idx in vms.indices {
                    let v = vms[idx]
                    print("\(v.date) \(v.name ?? v.counterpartyAddress) \(v.outgoing ? "-" : "+")\(v.amount) \(v.balanceAfter)")
                }

                self.recentTxs = vms

            } catch {
                DebugLogger.log("⚠️ refreshOnChainData failed: \(error)")
            }
        }
    }

    @MainActor
    func removeEmail(_ emailToRemove: String) {
        let newEmails = email.filter { $0.lowercased() != emailToRemove.lowercased() }
        // Only proceed if at least one handle remains overall
        if !newEmails.isEmpty || !phone.isEmpty {
            Task {
                do {
                    try await FirebaseService.shared.removeEmail(emailToRemove)
                } catch {
                    // Handle the error: e.g., show alert if it was the last provider
                    DebugLogger.log("❌ Error unlinking email: \(error.localizedDescription)")
                    return
                }
                email = newEmails
            }
        } else {
            DebugLogger.log("⚠️ Cannot remove the last contact handle")
        }
    }

    @MainActor
    func removePhone(_ phoneToRemove: String) {
        let newPhones = phone.filter { $0 != phoneToRemove }
        if !newPhones.isEmpty || !email.isEmpty {
            Task {
                do {
                    try await FirebaseService.shared.removePhone(phoneToRemove)
                } catch {
                    DebugLogger.log("❌ Error unlinking phone: \(error.localizedDescription)")
                    return
                }
                phone = newPhones
            }
        } else {
            DebugLogger.log("⚠️ Cannot remove the last contact handle")
        }
    }

    @MainActor func reloadAvatarIfNeeded() async {
        guard avatarUrl != nil else { return }
        do {
            let data = try await FirebaseService.shared.fetchThumbData()
            if let ui = UIImage(data: data) {
                avatar = Image(uiImage: ui)
            }
        } catch {
            DebugLogger.log("⚠️ failed to reload avatar: \(error)")
        }
    }

    func uploadAvatar(from item: PhotosPickerItem) async {
        removeImage()

        guard
            let data = try? await item.loadTransferable(type: Data.self),
            let uiImg = UIImage(data: data)
        else { return }

        await MainActor.run {
            self.avatar = Image(uiImage: uiImg)
            saveImage(img: uiImg)
        }

        do {
            let url = try await FirebaseService.shared.uploadAvatar(uiImg)
            await MainActor.run {
                self.avatarUrl = url.absoluteString
            }
        } catch {
            DebugLogger.log("❌ Upload failed: \(error)")
        }
    }

    func removeImage() {
        UserDefaults.standard.set(nil, forKey: "avatar")
    }

    func saveImage(img: UIImage) {
        guard let data = img.jpegData(compressionQuality: 0.8) else { return }
        let encoded = try! PropertyListEncoder().encode(data)
        UserDefaults.standard.set(encoded, forKey: "avatar")
    }

    func loadImage() {
        guard let data = UserDefaults.standard.data(forKey: "avatar") else { return }
        let decoded = try! PropertyListDecoder().decode(Data.self, from: data)
        if let img = UIImage(data: decoded) {
            avatar = Image(uiImage: img)
        }
    }

    @MainActor func nukeAccount() async {
        onboardingStep = .splash

        await FirebaseService.shared.removeUserData()

        FirebaseService.shared.deleteAvatarFolder { result in
            switch result {
            case .success:
                print("Avatar folder cleared")
            case let .failure(err):
                DebugLogger.log("⚠️ Error clearing avatar folder: \(err.localizedDescription)")
            }
        }

        FirebaseService.shared.logoutUser()

        KeychainWrapper.standard.removeObject(forKey: "seedWords")

        avatar = nil
        avatarUrl = nil
        displayName = ""
        walletAddress = ""
        seedWords = []

        phone = []
        email = []
        viewedFAQIDs = []

        adaBalance = 0
        hoskyBalance = 0

        removeImage()

        WalletService.shared.clearCache()

        UserDefaults.standard.set(nil, forKey: "EmailForSignIn")
        UserDefaults.standard.set(nil, forKey: "pendingEmail")
        UserDefaults.standard.set(nil, forKey: "PhoneForSignIn")
        UserDefaults.standard.set(nil, forKey: "phoneVID")
    }
}

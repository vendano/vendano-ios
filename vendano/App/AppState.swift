//
//  AppState.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/7/25.
//

import PhotosUI
import SwiftUI
import UIKit

import os

final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var onboardingStep: OnboardingStep = .splash

    @Published var seedWords: [String] = []
    @Published var seedLanguage: MnemonicLanguage = .app

    @Published var avatar: Image?
    @Published var avatarUrl: String?
    @Published var displayName: String = ""
    @Published var otpEmail: String?
    @Published var otpPhone: String?
    @Published var phone: [String] = []
    @Published var email: [String] = []
    @Published var walletAddress: String = "" {
        didSet {
            Task { @MainActor in
                self.checkingTxs = true
                WalletService.shared.clearCache()
                refreshOnChainData()
            }
        }
    }

    @Published var viewedFAQIDs: Set<String> = []
    @Published var checkingTxs: Bool = false
    @Published var recentTxs: [TxRowViewModel] = []
    
    @Published var displayToast = false
    @Published var toastMessage = ""
    
    @Published var sendToAddress: String? = nil
    
    @Published var isExpertMode: Bool = UserDefaults.standard.bool(forKey: "VendanoExpertMode") {
        didSet {
            UserDefaults.standard.set(isExpertMode, forKey: "VendanoExpertMode")
        }
    }
    
    @Published var FAQs: FAQDocument?
    
    var allFAQs: [FAQItem] {
        FAQs?.sections.flatMap(\.items) ?? []
    }
    
    @Published var environment: AppEnvironment = .mainnet
    
    func setEnvironment(_ env: AppEnvironment) {
        environment = env
        DebugLogger.log("🌐 Environment set to \(env.rawValue)")
    }
    
    func resolveEnvironment(for identifier: String) -> AppEnvironment {
        // Special demo account
        if identifier.lowercased() == "apple@vendano.net" {
            return .appstorereview
        }
        
        // hardcoded test users for staging
        if identifier.lowercased().hasSuffix("@test.vendano.net") {
            return .testnet
        }
        
        return .mainnet
    }
    
    @MainActor
    func loadFAQ() {
        do { FAQs = try FAQLoader.load() }
        catch { print("FAQ load error:", error) }
    }
    
    @MainActor
    func showToast(_ message: String, duration: TimeInterval = 2.0) {
        toastMessage = message
        withAnimation { displayToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation { self.displayToast = false }
        }
    }

    @MainActor func refreshOnChainData() {
        Task {
            guard !walletAddress.isEmpty else {
                checkingTxs = false
                return
            }
            do {
                // 1) Refresh balances first (spendable + expert totals)
                await WalletService.shared.refreshBalancesFromChain()
                // 2) Price
                await WalletService.shared.loadPrice()

                let ada = WalletService.shared.adaBalance
                guard ada > 0 else {
                    await MainActor.run { checkingTxs = false }
                    return
                }

                AnalyticsManager.logOnce("receive_success", parameters: ["amount": ada])

                let raws = try await WalletService.shared.fetchTransactionsOnce(for: walletAddress)

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

                // Treat *all* our account addresses as ours, not just walletAddress.
                let myAddresses = Set(WalletService.shared.allAddresses + [walletAddress])
                DebugLogger.log("🔎 WalletAddress = \(walletAddress)")
                DebugLogger.log("🔎 Known account addresses (\(myAddresses.count)):")
                for addr in myAddresses {
                    DebugLogger.log("   • \(addr)")
                }

                var running = ada
                var vms: [TxRowViewModel] = []

                for tx in sortedByBlockAndTime {
                    DebugLogger.log("🔍 --- TX \(tx.hash) height=\(tx.blockHeight) date=\(tx.date)")

                    // Dump raw inputs/outputs so we can inspect every UTxO
                    for input in tx.inputs {
                        let mineMark = myAddresses.contains(input.address) ? "*" : " "
                        DebugLogger.log(
                            "    IN \(mineMark) \(input.address) \(Double(input.amount) / 1_000_000) ADA"
                        )
                    }
                    for output in tx.outputs {
                        let mineMark = myAddresses.contains(output.address) ? "*" : " "
                        DebugLogger.log(
                            "    OUT\(mineMark) \(output.address) \(Double(output.amount) / 1_000_000) ADA"
                        )
                    }

                    // Net movement for THIS WALLET (all its addresses):
                    // +ve = incoming, -ve = outgoing
                    let myInputSum = tx.inputs
                        .filter { myAddresses.contains($0.address) }
                        .map(\.amount)
                        .reduce(0, +)

                    let myOutputSum = tx.outputs
                        .filter { myAddresses.contains($0.address) }
                        .map(\.amount)
                        .reduce(0, +)

                    let netLovelace = Int64(myOutputSum) - Int64(myInputSum)
                    let netAda = Double(netLovelace) / 1_000_000

                    DebugLogger.log(
                        "    myInputSum=\(Double(myInputSum)/1_000_000) " +
                        "myOutputSum=\(Double(myOutputSum)/1_000_000) netAda=\(netAda)"
                    )

                    // Skip pure no-op txs
                    guard netAda != 0 else {
                        DebugLogger.log("    (ignored: netAda == 0)")
                        continue
                    }

                    let outgoing = netAda < 0
                    let movedAda = abs(netAda)

                    // We're iterating newest -> oldest, so:
                    // running = current balance *after* all later txs
                    // balanceAfter = what wallet shows right after THIS tx
                    let balanceAfter = running
                    running -= netAda  // undo this tx going backwards

                    // Counterparty: any address not in myAddresses
                    let peers: [String]
                    if outgoing {
                        // Outgoing: look at outputs that are not us
                        peers = tx.outputs.map(\.address).filter { !myAddresses.contains($0) }
                    } else {
                        // Incoming: look at inputs that are not us
                        peers = tx.inputs.map(\.address).filter { !myAddresses.contains($0) }
                    }

                    let outTx = tx.outputs.first?.address
                    let inTx = tx.inputs.first?.address

                    let fallbackCounterparty: String? = {
                        if outgoing {
                            if let o = outTx, !myAddresses.contains(o) { return o }
                            if let i = inTx, !myAddresses.contains(i) { return i }
                        } else {
                            if let i = inTx, !myAddresses.contains(i) { return i }
                            if let o = outTx, !myAddresses.contains(o) { return o }
                        }
                        return nil
                    }()

                    let counterparty = peers.first ?? fallbackCounterparty ?? "Unknown"

                    DebugLogger.log(
                        "    -> outgoing=\(outgoing) moved=\(movedAda) " +
                        "balanceAfter=\(balanceAfter) counterparty=\(counterparty)"
                    )

                    vms.append(.init(
                        id: tx.hash,
                        date: tx.date,
                        outgoing: outgoing,
                        amount: movedAda,
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

//                for idx in vms.indices {
//                    let v = vms[idx]
//                    print("\(v.date) \(v.name ?? v.counterpartyAddress) \(v.outgoing ? "-" : "+")\(v.amount) \(v.balanceAfter)")
//                }

                await MainActor.run {
                    self.checkingTxs = false
                    self.recentTxs = vms
                }

            } catch {
                DebugLogger.log("⚠️ refreshOnChainData failed: \(error)")
                await MainActor.run { self.checkingTxs = false }
            }
        }
    }

    @MainActor func removeEmail(_ emailToRemove: String) {
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

    @MainActor func removePhone(_ phoneToRemove: String) {
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

    func uploadAvatar(from uiImg: UIImage) async {
        os_log("uploadAvatar called on main? %{public}@", #function)

        await MainActor.run {
            removeImage()
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

    func uploadAvatar(from item: PhotosPickerItem) async {
        guard
            let data = try? await item.loadTransferable(type: Data.self),
            let uiImg = UIImage(data: data)
        else { return }

        await uploadAvatar(from: uiImg)
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

    @MainActor func removeWallet() {
        walletAddress = ""
        seedWords = []

        KeychainWrapper.standard.removeObject(forKey: "seedWords")

        WalletService.shared.clearCache(preserveBalances: false)

        recentTxs.removeAll()

        onboardingStep = .walletChoice
    }

    @MainActor func nukeAccount() async {
        removeWallet()

        onboardingStep = .splash

        FirebaseService.shared.deleteAvatarFolder { result in
            switch result {
            case .success: print("Avatar folder cleared")
            case let .failure(err): DebugLogger.log("⚠️ Error clearing avatar folder: \(err)")
            }
        }

        await FirebaseService.shared.removeUserData()

        FirebaseService.shared.logoutUser()

        avatar = nil
        avatarUrl = nil
        displayName = ""
        phone = []
        email = []
        viewedFAQIDs = []

        UserDefaults.standard.removeObject(forKey: "EmailForSignIn")
        UserDefaults.standard.removeObject(forKey: "VendanoEmailForLink")
        UserDefaults.standard.removeObject(forKey: "pendingEmail")
        UserDefaults.standard.removeObject(forKey: "PhoneForSignIn")
        UserDefaults.standard.removeObject(forKey: "phoneNumber")
        UserDefaults.standard.removeObject(forKey: "phoneVID")

        removeImage()
    }
}


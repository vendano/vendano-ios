//  ProximityPaymentService.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 1/2/26.
//

import Foundation
import MultipeerConnectivity
import UIKit

@MainActor
final class ProximityPaymentService: NSObject, ObservableObject {
    static let shared = ProximityPaymentService()

    enum Mode: Equatable {
        case idle
        case merchant(request: VendanoPaymentRequest)
        case payer
    }

    // MARK: - Published state (bindable)

    @Published private(set) var mode: Mode = .idle
    @Published private(set) var connectedPeerNames: [String] = []
    @Published var receivedRequest: VendanoPaymentRequest? = nil          // payer
    @Published var lastResponse: VendanoPaymentResponse? = nil            // merchant
    @Published var lastErrorMessage: String? = nil

    // MARK: - MPC internals

    private let serviceType = "vendano-pay"
    private let peerID = MCPeerID(displayName: UIDevice.current.name)
    nonisolated(unsafe) private lazy var session: MCSession = {
        let s = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        s.delegate = self
        return s
    }()

    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    private var currentMerchantRequest: VendanoPaymentRequest? = nil

    // MARK: - Lifecycle

    func stop() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil

        browser?.stopBrowsingForPeers()
        browser = nil

        session.disconnect()

        mode = .idle
        connectedPeerNames = []
        receivedRequest = nil
        lastResponse = nil
        lastErrorMessage = nil
        currentMerchantRequest = nil
    }

    // MARK: - Merchant

    func startMerchant(request: VendanoPaymentRequest) {
        stop()

        mode = .merchant(request: request)
        currentMerchantRequest = request

        let adv = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: ["v": "1"], serviceType: serviceType)
        adv.delegate = self
        adv.startAdvertisingPeer()
        advertiser = adv
    }

    // MARK: - Payer

    func startPayer() {
        stop()

        mode = .payer

        let b = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        b.delegate = self
        b.startBrowsingForPeers()
        browser = b
    }

    // MARK: - Messaging

    private enum Message: Codable {
        case request(VendanoPaymentRequest)
        case response(VendanoPaymentResponse)

        enum CodingKeys: String, CodingKey { case type, payload }
        enum Kind: String, Codable { case request, response }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let kind = try c.decode(Kind.self, forKey: .type)
            switch kind {
            case .request:
                self = .request(try c.decode(VendanoPaymentRequest.self, forKey: .payload))
            case .response:
                self = .response(try c.decode(VendanoPaymentResponse.self, forKey: .payload))
            }
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .request(let req):
                try c.encode(Kind.request, forKey: .type)
                try c.encode(req, forKey: .payload)
            case .response(let resp):
                try c.encode(Kind.response, forKey: .type)
                try c.encode(resp, forKey: .payload)
            }
        }
    }

    private func send(_ message: Message, to peers: [MCPeerID]? = nil) {
        do {
            let data = try JSONEncoder().encode(message)
            let targets = peers ?? session.connectedPeers
            guard !targets.isEmpty else { return }
            try session.send(data, toPeers: targets, with: .reliable)
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    // Called by merchant after connection
    private func sendCurrentRequestIfPossible() {
        guard case .merchant = mode, let req = currentMerchantRequest else { return }
        send(.request(req))
    }

    // Public: payer sends response back
    func sendResponse(_ response: VendanoPaymentResponse) {
        send(.response(response))
    }
}

// MARK: - MCSessionDelegate

extension ProximityPaymentService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            let names = session.connectedPeers.map { $0.displayName }.sorted()
            connectedPeerNames = names

            // When merchant connects, immediately push the request payload
            if case .merchant = mode, state == .connected {
                sendCurrentRequestIfPossible()
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            do {
                let msg = try JSONDecoder().decode(Message.self, from: data)
                switch msg {
                case .request(let req):
                    receivedRequest = req
                case .response(let resp):
                    lastResponse = resp
                }
            } catch {
                lastErrorMessage = error.localizedDescription
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - Advertiser

extension ProximityPaymentService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in
            lastErrorMessage = error.localizedDescription
        }
    }
}

// MARK: - Browser

extension ProximityPaymentService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Auto-invite first peer we see for MVP (Square-like “just tap” feel)
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            lastErrorMessage = error.localizedDescription
        }
    }
}

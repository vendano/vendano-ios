# Vendano iOS

### Simple, contact-based ADA for everyone

Vendano is an open-source iOS wallet that lets anyone **send and receive ADA (and native tokens) using a phone number or e-mail address** instead of a 58-character address.

The goal is to make Cardano transactions feel as familiar as texting: no arcane jargon and an interface that guides first-time users in plain language.

> **Why there’s room for Vendano**
> Most Cardano wallets excel at power-user features (staking dashboards, hardware-wallet pairing, multi-asset portfolios), yet still ask newcomers to master new concepts before they can move a single coin. Vendano's mission focuses on **on-ramp simplicity**: features such as verified contacts, one-tap transfers, and automatic on-chain “claim” flows for recipients who haven’t installed the app yet.

## Catalyst context

| Item                                                        | Catalyst requirement it satisfies |
| ----------------------------------------------------------- | --------------------------------- |
| Public TestFlight build (link in proposal)                  | Demonstrable MVP                  |
| README with build instructions & secrets policy (this file) | Technical transparency            |

*This repository is attached to our Fund 14 proposal. Milestone tags (`milestone-1`, `milestone-2`, …) will map 1-to-1 with Catalyst reports.*

## Feature snapshot

| Status | Feature                                                        |
| ------ | -------------------------------------------------------------- |
| ✅      | Phone number & e-mail link/claim protocol (hashed identifiers) |
| ✅      | Firebase phone OTP + Apple Sign-In                             |
| ✅      | ADA / asset send-receive with live fee preview                 |
| ✅     | Biometric-protected sending feature            |
| ⚠️     | Push notifications (“your contact just claimed ADA”)           |

## Architecture (repo snapshot – July 2025)

```text
VendanoApp (SwiftUI – iOS target)
│
├── App Layer
│   ├── VendanoApp.swift          – @main entry point
│   ├── AppState.swift            – global ObservableObject
│   └── Config.swift              – feature flags & constants
│
├── UI
│   ├── Views/                    – screen-level SwiftUI views
│   ├── Subviews/                 – reusable view components
│   └── Assets.xcassets/          – colours, icons, launch gradients
│
├── Domain
│   ├── Models/                   – value objects & view models
│   ├── Services/
│   │   ├── WalletService*.swift  – BIP-39, CIP-30, send flow
│   │   ├── FirebaseService.swift – phone OTP / Firestore sync
│   │   ├── PriceService.swift    – CoinGecko + Coinbase tickers
│   │   ├── DebugLogger.swift     – ring-buffer crash / user log
│   │   └── NetworkMonitor.swift  – reachability status
│   └── Extensions/               – String, Double, UIKit helpers
│
└── Project
    ├── vendano.xcodeproj/
    ├── vendano.entitlements

```

*SwiftUI; minimum iOS 16.*

## Getting started (local build)

1. **Clone**

   ```bash
   git clone git@github.com:jeffreality/vendano-ios.git
   cd vendano-ios
   ```

2. **Secrets**

   The repo **omits** `Info.plist` and `GoogleService-Info.plist` to protect API keys.

   | File                       | Where to get it                                   | Notes                                                 |
   | -------------------------- | ------------------------------------------------- | ----------------------------------------------------- |
   | `vendano/Info.sample.plist` | Included template – copy to `Info.plist`          | Fill `BLOCKFROST_API_KEY` & `FIREBASE_PLIST_NAME`.    |
   | `vendano/App/GoogleService-Info.plist` | Firebase Console ▸ *Project Settings* ▸ *iOS app* | Place inside `App/` and reference in `Info.plist`. |

## Security & privacy

* Encrypted seed stored in Keychain; user must enable Face ID / Touch ID to send ADA.
* Firebase Auth for bot-resistant claims.
* Salted-hash identifiers (CIP-20 tag) so phone numbers/e-mails never appear on-chain or decrypted in Firestore.

## Roadmap (aligned to Catalyst milestones)

| Milestone | Deliverables (evidence) | ETA | Budget |
| ------- | ------ | ------- | ------ |
| **M-1** | iOS v1.0 Launch | 2025-09 | 40 % |
| **M-2** | Android MVP | 2025-12 | 35 % |
| **M-3** | Android Stable + Cross-platform parity | 2026-02 | 25 % |


## Contributing

Issues and PRs are restricted to maintainers while the Catalyst audit is in progress. If you’re a developer or designer keen to help, open a **Discussion** or ping `@jeffreality` in **#dev-mobile** on the *Cardano Builders Guild* Discord.

## All Rights Reserved

*Vendano iOS* is shared **solely for evaluation as part of a Project Catalyst Fund 14 submission**. Cloning, redistribution, or commercial use outside the Catalyst review process is not permitted without prior written consent.

&copy; 2025 Vendano LLC.  All rights reserved.
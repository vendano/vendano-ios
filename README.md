# Vendano iOS

### Simple, contact-based ADA for everyone

Vendano is an open-source iOS wallet that lets anyone **send and receive ADA (and native tokens) using a phone number or e-mail address** instead of a 58-character address.

The goal is to make Cardano transactions feel as familiar as texting: no arcane jargon and an interface that guides first-time users in plain language.

> **Why there’s room for Vendano**
> Most Cardano wallets excel at power-user features (staking dashboards, hardware-wallet pairing, multi-asset portfolios), yet still ask newcomers to master new concepts before they can move a single coin. Vendano's mission focuses on **on-ramp simplicity**: features such as verified contacts, one-tap transfers, and automatic on-chain “claim” flows for recipients who haven’t installed the app yet.

### Repository Overview

**vendano-ios** is the code for the client app of the Vendano wallet. This repository contains the SwiftUI-based codebase for iOS 16+, organized to support review of architecture, data flows, and security/privacy practices. `Info.plist` and `GoogleService-Info.plist` are intentionally omitted to avoid publishing secrets. The code is in active development and is intended to be compiled and shipped after review.

### Security and privacy notes

- Seed handling: seeds are stored in the Keychain and protected by device biometrics where available.
- Authentication: Firebase-based authentication flows; ensure proper handling of OTPs and privacy.
- Data minimization: hashed identifiers are used for contact-based sending to avoid exposing raw phone numbers or emails.
- Secrets exposure: no API keys or secrets are committed to the repository; Info.plist and GoogleService-Info.plist are kept out of version control.

### Review and contributing

- Reviewers: focus on seed handling, authentication flows, data flows (hashed contacts), network calls, and how secrets are managed.
- See CONTRIBUTING.md for how to propose changes, run checks, and file security concerns.
- If you identify security concerns, please open an issue or a pull request with a clear description and steps to reproduce.

### Licensing

BSD 3-Clause

### Contact

- Support: support@vendano.net
- Website: https://vendano.net
- Policy pages (privacy/terms): https://vendano.net/privacy.html, https://vendano.net/terms.html
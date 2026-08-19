# Vendano Security Policy

Vendano is a self-custody Cardano wallet. Security reports and careful review are welcome.

## Supported versions

Security fixes are applied to the current App Store release and the active `main` branch. Older builds may not receive fixes. Users should install the latest version available through Apple’s App Store.

## Reporting a vulnerability

Do not report a suspected vulnerability through a public issue, discussion, pull request, social-media post, or shared screenshot.

Send the report privately to support@vendano.net with `[SECURITY]` in the subject line. If GitHub private vulnerability reporting is enabled for this repository, that channel may also be used.

Please include:

- The affected version, commit, or file.
- A description of the issue and its likely impact.
- Reproduction steps or a minimal proof of concept.
- Whether real funds or personal information may be at risk.
- Any suggested mitigation, if known.

Do not include a real recovery phrase, private key, authentication token, production credential, or another person’s personal information. Use test wallets and test data wherever possible.

Vendano does not currently operate a formal bug-bounty program. Please allow a reasonable opportunity to investigate and correct a report before public disclosure.

## Current security architecture

### Recovery-phrase generation

Vendano supports 12-, 15-, and 24-word BIP-39 recovery phrases, corresponding to 128, 160, and 256 bits of entropy.

Mnemonic generation is supplied by the pinned Bip39.swift and UncommonCrypto dependencies. On Apple platforms, the entropy source resolves to `SecRandomCopyBytes` using `kSecRandomDefault`. Vendano does not implement a custom pseudorandom-number generator.

### Key derivation and transaction signing

Cardano key derivation, transaction construction, and signing are delegated to the versions of Cardano.swift and cardano-serialization-lib recorded in `Package.resolved`.

Vendano does not implement its own Ed25519 signing primitive, random signing nonce, or elliptic-curve arithmetic. These dependencies remain part of the application’s security boundary and must be reviewed carefully when updated.

### On-device storage

The recovery phrase is encoded and stored as a Keychain item. Its current accessibility behavior is the iOS when-unlocked default.

Before submitting a transaction, the application requests device-owner authentication through LocalAuthentication when the device supports that policy. Depending on device configuration, this can use Face ID, Touch ID, or the device passcode.

This authorization prompt is distinct from Keychain access control: the current recovery-phrase item is not configured with `SecAccessControl` to require user presence every time it is read.

### Sensitive-screen handling

The application obscures its interface when it moves out of the active foreground state, reducing exposure through the application switcher. It also warns the user when a screenshot is detected while displaying recovery information.

iOS does not allow an application to guarantee that screenshots or external photographs cannot be taken. Users remain responsible for protecting recovery information from visual capture.

### Authentication and contact discovery

Firebase Authentication provides phone-number OTP and email-link authentication.

Vendano does not upload the user’s address book. A user may explicitly associate verified phone numbers or email addresses with an account.

Raw verified handles are stored in the authenticated user’s private account data. Public contact-discovery records use normalized SHA-256 hashes. Hashing avoids publishing a handle directly, but it is not encryption and does not make a low-entropy value such as a phone number anonymous. An attacker may be able to test candidate values.

### Network and blockchain data

Vendano uses Firebase for authentication and application data and Blockfrost for Cardano network access.

Cardano wallet addresses, transaction identifiers, transferred assets, amounts, and related metadata are public blockchain information. No wallet should promise transaction anonymity that Cardano itself does not provide.

Recovery phrases and private keys must not be intentionally transmitted to Firebase, Blockfrost, analytics providers, or application support.

### Configuration and credentials

Production Firebase configuration, Blockfrost credentials, Apple signing identities, entitlements, and other environment-specific values are not distributed as reusable credentials through the public repository.

Developers building a fork must supply and protect their own configuration.

## Known limitations

- Vendano has not undergone an independent third-party security audit.
- Public SHA-256 contact hashes may be susceptible to enumeration or dictionary attacks.
- The recovery-phrase Keychain item does not currently require per-read biometric or user-presence authorization.
- A compromised, jailbroken, or maliciously administered device can undermine operating-system security guarantees.
- Anyone who obtains the recovery phrase can control the wallet.
- Vendano cannot recover a lost recovery phrase or reverse a confirmed blockchain transaction.
- Third-party libraries and remote services remain part of the application’s security boundary.

## Security requirements for contributions

Changes involving entropy, mnemonics, key derivation, Keychain storage, authentication, signing, transaction serialization, contact discovery, or dependency versions require focused review.

Contributors must:

- Avoid custom cryptographic implementations.
- Use documented operating-system security facilities.
- Preserve dependency pinning and explain dependency changes.
- Add known-answer or published test vectors where applicable.
- Never log recovery words, private keys, OTPs, authentication tokens, or production credentials.
- Redact phone numbers, email addresses, wallet addresses, transaction identifiers, and user-provided error content from diagnostic logs unless strictly necessary and explicitly reviewed.
- Use synthetic test data.
- Document any change to remotely stored data, analytics, or retention behavior.

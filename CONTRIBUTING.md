# Contributing to Vendano iOS

Thank you for helping improve Vendano.

Vendano handles recovery phrases, private keys, identity information, and financial transactions. Changes that appear small can have significant security or privacy consequences, so contributions should be narrow, documented, and reproducible.

## Before starting

- Search existing issues and pull requests for related work.
- Open a proposal issue before undertaking a large architectural or user-interface change.
- Report suspected vulnerabilities privately according to `SECURITY.md`; do not open a public issue.
- Never use real recovery phrases, private keys, phone numbers, email addresses, authentication tokens, or production credentials in development material.

## Development configuration

End users install the signed application through Apple’s App Store. Developers compiling the source must provide their own development configuration, including any required Firebase project, Blockfrost credentials, Apple signing identity, bundle configuration, and entitlements.

Do not commit development or production secrets. Before opening a pull request, inspect the complete diff and commit history for accidental credentials or personal data.

## Pull-request process

The `main` branch is protected. Changes must be submitted through a pull request.

A pull request should:

- Address one reasonably focused change.
- Explain the user-facing behavior and motivation.
- Identify security, privacy, networking, data-storage, and compatibility effects.
- Include build and test results.
- Include screenshots for visual changes, using synthetic accounts and data.
- Update documentation and localization when behavior changes.
- Avoid unrelated formatting or mechanical changes.

## Security-sensitive changes

The following areas require focused security review:

- Recovery-phrase generation or presentation.
- Entropy and random-number generation.
- Key derivation and transaction signing.
- Keychain storage or device authentication.
- Firebase authentication and authorization.
- Contact discovery and identifier hashing.
- Transaction construction and network submission.
- Dependency or lockfile changes.
- Analytics, logging, diagnostics, or remote data storage.

Do not introduce custom cryptographic primitives, signature algorithms, nonce generation, random-number generators, or modified mnemonic wordlists.

Dependency changes must explain why the update is required, identify relevant upstream release notes, preserve version pinning, and include appropriate regression or known-answer tests.

## Logging and test data

Never log or include in analytics:

- Recovery words or private keys.
- OTPs, authentication links, or tokens.
- Production credentials.
- Unredacted personal information.
- Complete diagnostic payloads that may contain user-supplied secrets.

Use generated test wallets and synthetic identities. Redact wallet addresses and transaction identifiers from screenshots and issue reports unless their public disclosure is deliberate and necessary.

## Localization

Vendano currently includes English, Japanese, Korean, US Spanish, and Latin American Spanish application resources, along with localized FAQ content.

For user-facing changes:

1. Add or update the English source string.
2. Update every supported `.lproj` localization.
3. Preserve placeholders such as `%@`, `%d`, and positional arguments exactly.
4. Update the corresponding localized `FAQs.json` when help or instructional behavior changes.
5. Run `vendano/Localization/strings_diff.sh` to identify missing or extra keys.
6. Verify the result in the interface, including longer strings, line wrapping, buttons, Dynamic Type, and right-to-left assumptions where relevant.

Security warnings, recovery instructions, transaction confirmations, fee descriptions, and irreversible-action language require human review. Do not ship these based solely on unreviewed machine translation.

Mnemonic wordlists are protocol data, not interface translations. Do not add, reorder, translate, or otherwise modify their entries without a separately reviewed protocol-level change.

## Accessibility and user experience

Vendano is intended to make Cardano understandable to people who are not cryptocurrency experts.

New interfaces should:

- Use plain language before technical terminology.
- Clearly distinguish reversible and irreversible actions.
- Support Dynamic Type and VoiceOver where practical.
- Avoid relying only on color to communicate state.
- Preserve clear confirmation and failure states.
- Explain fees, recipient identity, and transaction finality before submission.

## Licensing of contributions

Unless explicitly agreed otherwise in writing, contributions submitted to this repository are provided under the repository’s BSD 3-Clause License.

The software license does not grant rights to use Vendano trademarks or brand assets in a separately distributed application. See `TRADEMARKS.md`.

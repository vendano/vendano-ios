//
//  FAQItem.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/5/25.
//

import SwiftUI

struct FAQItem: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let question: String
    let tldr: String
    let answer: String
    let clarify: String
    let details: String
}

class FAQs {
    static let shared = FAQs()

    let onboarding: [FAQItem] = [
        .init(icon: "₳",
              question: "What’s Cardano/ADA?",
              tldr: "A cryptocurrency.",
              answer: "Cardano is a public blockchain (an open ledger) and ADA is its currency.",
              clarify: "Cardano is an open-source blockchain. Every transaction is recorded on a public ledger. ADA is the currency you hold and transfer on that ledger.",
              details: "Think of Cardano as a giant spreadsheet everyone can see but no one can secretly edit. Every ADA transfer is written to that spreadsheet forever, so no bank can delete or \"undo\" your money. ADA is just the unit recorded in each cell—like dollars in a bank ledger. Cardano’s standout feature is its scientific \"proof-of-stake\" design (energy-light and peer-reviewed) compared with Bitcoin’s energy-heavy mining."),
        .init(icon: "shield",
              question: "Is this safe?",
              tldr: "Your word phrase secures everything.",
              answer: "Only your secret 12/15/24 word phrase can move your ADA. Keep it offline.",
              clarify: "Your ADA can only move with your secret 12/15/24 word recovery phrase. Make sure you keep a physical record of it somewhere safe. Vendano never stores private keys on its servers.",
              details: "Those 12/15/24 words are your private key. Lose them and no one - not even Vendano - can recover your funds; share them and anyone can empty your wallet. We store only encrypted public information on our servers; private keys never leave your device. Cardano’s proof-of-stake model removes mining hacks like \"51 % attacks,\" but your own key hygiene (writing the phrase on paper, not screenshots) is the single most important safety step."),
        .init(icon: "folder",
              question: "Where’s my ADA stored?",
              tldr: "In your Cardano address on-chain.",
              answer: "On the Cardano blockchain, inside your wallet address. Vendano never holds your funds.",
              clarify: "Funds live on the Cardano blockchain at your wallet address. Vendano is just a tool that builds and signs transactions from your phone.",
              details: "Imagine your wallet address as a PO Box number printed on every package (transaction) you send or receive. The box itself lives in the global Cardano network, not inside the app. Vendano helps you write new labels (transactions) and digitally sign them with your 12/15/24-word key; it never touches the contents of the box. Delete the app, reinstall on a new phone, enter your phrase, and the box - and all the ADA inside - re-appear."),
        .init(icon: "lock.doc",
              question: "Who can see my data?",
              tldr: "Only you.",
              answer: "Just you. Vendano stores only a salted hash of your email/phone — no personal data on-chain.",
              clarify: "Vendano hashes your email / phone before storing it, so no one (including Vendano) can reverse-look-up your personal info.",
              details: "We ask for email or phone so others can find you. Before storing, we hash (mathematically scramble) that string with a random salt; even Vendano staff can’t reverse it. On-chain we publish nothing personal - only Cardano addresses and transaction numbers the blockchain itself requires. Your avatar and display name is the only data that Vendano stores, so other people can find and confirm they are sending ADA to you."),
        .init(icon: "arrow.right.arrow.left",
              question: "How can I get ADA?",
              tldr: "Buy on an exchange then transfer in.",
              answer: "Create a wallet here, then buy ADA on an exchange (e.g. Coinbase) and send it to your Vendano address.",
              clarify: "Create or load a Cardano wallet here, copy the receive address, then purchase ADA on an exchange like Coinbase or Kraken and transfer it to the address of your Vendano wallet.",
              details: "Exchanges convert dollars to ADA much like a foreign currency booth converts USD to EUR. After purchase, use the exchange’s \"withdraw\" or \"send\" button, paste your Vendano receive address, and confirm. Within a minute or two you’ll see the ADA on your Home screen. Fees vary by exchange; Cardano’s small on-chain fee is baked into the transaction (those fees are used to maintain and support the software).")
    ]

    let additional: [FAQItem] = [
        .init(icon: "bolt.circle",
              question: "Why Cardano over Bitcoin or Ethereum?",
              tldr: "Greener, cheaper, still programmable.",
              answer: "Cardano uses proof-of-stake for low energy and averages < $0.20 per transaction.",
              clarify: "Bitcoin is slow + energy-heavy; Ethereum flexible but has high gas fees. Cardano hits the middle ground: smart contracts without high costs.",
              details: "Cardano’s proof-of-stake means no mining farms. That keeps fees low (fractions of a cent) and the network carbon-light. Its smart-contract layer (Plutus) lets you build NFTs and DeFi like Ethereum, but with predictable fees and peer-reviewed research behind every upgrade."),

        .init(icon: "iphone.slash",
              question: "What if I lose my phone?",
              tldr: "Re-install & enter your 12/15/24 words.",
              answer: "Funds live on the blockchain, not the device.",
              clarify: "Your 12/15/24-word phrase restores the wallet on any phone or computer that supports Cardano.",
              details: "Deleting Vendano - or losing your phone - doesn’t touch the ADA on-chain. Install any Cardano wallet, enter the phrase, and the same addresses (and balance) repopulate automatically. Without the phrase, nobody - neither Vendano nor Cardano’s developers - can access those funds."),

        .init(icon: "percent",
              question: "Why does Vendano charge \(Config.vendanoAppFeePercentFormatted) ?",
              tldr: "Server + support costs",
              answer: "1% keeps the lights on and is ~⅓ normal app fees.",
              clarify: "Traditional fiat apps add 3% plus hidden FX costs. Cardano’s low network fee lets us charge a flat \(Config.vendanoAppFeePercentFormatted).",
              details: "Each Cardano transaction costs ~0.17 ADA on-chain. Vendano adds \(Config.vendanoAppFeePercentFormatted) so we can run secure servers, pay for SMS / email OTPs, and keep improving features like staking or biometrics. There are no hidden spreads or monthly charges."),
        
        .init(
            icon: "arrow.triangle.2.circlepath.circle",
            question: "Can I use my Vendano funds in another wallet (like Yoroi)?",
            tldr: "Yes, restore it with your 12/15/24 words.",
            answer: "Every wallet that supports Cardano can load your funds. In Yoroi (or Daedalus, Nami, etc.), choose “Restore Wallet” and enter your 12/15/24‑word recovery phrase. Your ADA will appear immediately.",
            clarify: "Your 12/15/24‑word phrase is universal. Copy it exactly into any Cardano wallet app’s restore feature.",
            details: "1. Open Yoroi and pick “Restore”\n 2. Select “Shelley/Byron” era (if prompted)\n 3. Enter the same 12/15/24 words you wrote down\n 4. Give the wallet a name and optional password\n 5. Hit “Restore” and watch your ADA balance sync"
        ),
        
        .init(
            icon: "trash.circle",
            question: "How do I delete my Vendano account and data?",
            tldr: "Use the “Delete account” button in Settings.",
            answer: "Go to Profile → Danger Zone → Delete account. That erases your local keys and tells our server to forget your email/phone lookup. Your ADA stays safe on-chain; you can always restore with your 12/15/24 words.",
            clarify: "Deleting your Vendano account only removes app data. Your ADA never leaves the blockchain.",
            details: "• In the app: tap your avatar → scroll to “Danger Zone” → tap “Delete account”\n • Confirm the prompt; this clears everything stored locally and remotely\n • To use Vendano again, just reinstall and restore with your 12/15/24‑word phrase"
        ),

        .init(icon: "building.columns",
              question: "What happens if Vendano shuts down?",
              tldr: "Use any Cardano wallet.",
              answer: "Your 12/15/24-word phrase is standard BIP-39.",
              clarify: "Import that phrase into Daedalus, Eternl, Nami, Yoroi, etc. and your ADA is right there.",
              details: "Because your funds live on the blockchain and your key uses the open BIP-39 spec, you’re never locked in. Even if Vendano disappeared tomorrow, you could take your phrase to another wallet and continue transacting without interruption or fees."),

        .init(icon: "magnifyingglass",
              question: "Where can I verify all this?",
              tldr: "cardano.org, cardanoscan.io.",
              answer: "Everything is public—check fees, docs, and live transactions.",
              clarify: "Cardano is open source; use explorers to see any address or block.",
              details: "• Learn at cardano.org (official docs).\n• Inspect any transaction on cardanoscan.io.\n• Compare network fees at fees.cardano.org.\nOpen data means you don’t have to trust Vendano’s word—verify on the blockchain and independent sites.")
    ]

    // TODO: Future functionality
    //
    /*
     .init(icon: "checkmark.shield",
           question: "Can I earn rewards (staking)?",
           tldr: "Yes, stake it in this app.",
           answer: "Delegate your ADA to a pool and earn ~3–4 % yearly.",
           clarify: "Staking helps secure the network; rewards deposit automatically every 5 days.",
           details: "Open **Delegate** → pick a stake pool → tap *Delegate*. Your ADA never leaves the wallet; the protocol just counts your stake toward the pool. Rewards are automatic and liquid; you can send ADA at any time without ‘unstaking’ or lock-up periods."
          ),
    */

    func fullFAQs() -> [FAQItem] {
        return onboarding + additional
    }
}

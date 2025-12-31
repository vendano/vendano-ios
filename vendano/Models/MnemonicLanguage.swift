//
//  MnemonicLanguage.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 12/29/25.
//

import Foundation
import Bip39

enum MnemonicLanguage: String, CaseIterable, Codable {
    case app
    case english
    case japanese
    case korean
    case spanish
    case chineseSimplified
    case chineseTraditional
    case french
    case italian
    case czech
    case portuguese

    var wordlist: Wordlist {
        switch self {
        case .app:
            switch Locale.current.language.languageCode {
            case .english: return .english
            case .japanese: return .japanese
            case .korean: return .korean
            case .spanish: return .spanish
            case .chinese: return .chineseSimplified
            case .french: return .french
            case .italian: return .italian
            case .czech: return .czech
            case .portuguese: return .portuguese
            default: return .english
            }
        case .english: return .english
        case .japanese: return .japanese
        case .korean: return .korean
        case .spanish: return .spanish
        case .chineseSimplified: return .chineseSimplified
        case .chineseTraditional: return .chineseTraditional
        case .french: return .french
        case .italian: return .italian
        case .czech: return .czech
        case .portuguese: return .portuguese
        }
    }

    /// For display (and if words are ever re-joined into a sentence string).
    /// Japanese is a special case per the BIP39 wordlist notes.
    var displaySeparator: String {
        self == .japanese ? "\u{3000}" : " "
    }
}

enum MnemonicDetector {
    static func detectLanguage(words: [String]) -> MnemonicLanguage? {
        let candidates = MnemonicLanguage.allCases.filter { $0 != .app }

        let normalized = words.map { MnemonicText.nfkd($0).lowercased() }

        let matches = candidates.filter { lang in
            Mnemonic.isValid(phrase: normalized, wordlist: lang.wordlist)
        }

        if matches.count == 1 { return matches[0] }
        if matches.isEmpty { return nil }

        // Prefer locale if it’s one of the matches; else English; else first stable
        let localeResolved = MnemonicLanguage.app.wordlist
        if matches.contains(where: { $0.wordlist == localeResolved }) { return .app }
        return matches.contains(.english) ? .english : matches[0]
    }
}

enum MnemonicCanonicalizer {
    static func toEnglishWords(_ words: [String], language: MnemonicLanguage? = nil) throws -> (english: [String], used: MnemonicLanguage) {
        // normalize input words for lookup
        let normalized = words.map { MnemonicText.nfkd($0).lowercased() }

        // pick language: explicit > autodetect > fallback to app > english
        let usedLang: MnemonicLanguage = {
            if let language, language != .app { return language }
            if let detected = MnemonicDetector.detectLanguage(words: normalized), detected != .app { return detected }
            return .app
        }()

        // If .app, resolve to the actual app locale wordlist
        let resolvedLang: MnemonicLanguage = (usedLang == .app) ? .app : usedLang
        let wl = resolvedLang.wordlist

        // decode entropy using the correct wordlist
        let entropy = try Mnemonic.toEntropy(normalized, wordlist: wl)

        // re-encode as English (so Keychain can parse it)
        let english = try Mnemonic.toMnemonic(entropy, wordlist: .english)

        return (english, resolvedLang)
    }
}

//
//  ReinstallAuthEnforcer.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 9/4/25.
//

import FirebaseAuth

enum InstallMarker {
    static let key = "vendano.install_id"
}

enum ReinstallAuthEnforcer {
    static func run() {
        let defaults = UserDefaults.standard
        let isFirstRunAfterInstall = (defaults.string(forKey: InstallMarker.key) == nil)

        guard isFirstRunAfterInstall else { return }

        // If Firebase still has a session in Keychain, force sign-out so we prompt for login again.
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
                DebugLogger.log("Forced sign-out on first run after reinstall.")
            } catch {
                DebugLogger.log("Sign-out failed: \(error)")
            }
        }

        // Stamp this install so we don’t do this again on subsequent launches.
        defaults.set(UUID().uuidString, forKey: InstallMarker.key)
    }
}

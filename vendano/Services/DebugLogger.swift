//
//  DebugLogger.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/11/25.
//

import Foundation
import UIKit

enum DebugLogger {
    static let key = "debugLog"
    static let maxEntries = 30

    // Appends a message to the log with timestamp, capped to last `maxEntries`.
    static func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "[\(timestamp)] \(message)"

        var existing = UserDefaults.standard.stringArray(forKey: key) ?? []
        existing.append(entry)
        if existing.count > maxEntries {
            existing = Array(existing.suffix(maxEntries))
        }
        UserDefaults.standard.set(existing, forKey: key)
    }

    // Returns the full log plus device info as a string.
    static func getLogWithDeviceInfo() -> String {
        var log = (UserDefaults.standard.stringArray(forKey: key) ?? []).joined(separator: "\n")
        log += "\n\n--- DEVICE INFO ---\n"
        log += "Device: \(deviceModel())\n"
        log += "OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)\n"
        log += "App Version: \(appVersion())\n"
        return log
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    // Returns the device model (e.g. iPhone14,3).
    private static func deviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    // Returns the app version and build.
    private static func appVersion() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}

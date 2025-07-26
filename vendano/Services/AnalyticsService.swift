//
//  AnalyticsService.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/26/25.
//

import Foundation

protocol AnalyticsService {
    func logEvent(_ name: String, parameters: [String: Any]?)
    func setUserProperty(_ value: String?, for name: String)
}

enum AnalyticsManager {
    private static var currentService: AnalyticsService = FirebaseAnalyticsService()

    static func configure(with service: AnalyticsService) {
        currentService = service
    }

    static func logOnce(_ name: String, parameters: [String: Any]? = nil) {
        let key = "analytics_\(name)"
        let wasLogged = UserDefaults.standard.bool(forKey: key)
        if !wasLogged {
            logEvent(name, parameters: parameters)

            AnalyticsManager.setUserProperty(
                Date().ISO8601Format().stringValue,
                for: "\(name)_date"
            )

            UserDefaults.standard.set(true, forKey: key)
        }
    }

    static func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        print(name)
        currentService.logEvent(name, parameters: parameters)
    }

    static func setUserProperty(_ value: String?, for name: String) {
        currentService.setUserProperty(value, for: name)
    }
}

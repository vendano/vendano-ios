//
//  FirebaseAnalyticsService.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 7/26/25.
//

import FirebaseAnalytics

class FirebaseAnalyticsService: AnalyticsService {
    func logEvent(_ name: String, parameters: [String: Any]?) {
        Analytics.logEvent(name, parameters: parameters)
    }

    func setUserProperty(_ value: String?, for name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
}

//
//  NotificationPermissionManager.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 1/2/26.
//

import UserNotifications
import UIKit

@MainActor
final class NotificationPermissionManager: ObservableObject {
    static let shared = NotificationPermissionManager()

    func getStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { cont in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                cont.resume(returning: settings.authorizationStatus)
            }
        }
    }

    func request() async -> Bool {
        await withCheckedContinuation { cont in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
                cont.resume(returning: granted)
            }
        }
    }
}

//
//  VendanoApp.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/3/25.
//

import FirebaseAnalytics
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging
import SwiftUI
import UserNotifications

@main
struct VendanoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("appearancePreference") private var appearancePrefRaw = AppearancePreference.system.rawValue

    private var appearancePref: AppearancePreference {
        AppearancePreference(rawValue: appearancePrefRaw) ?? .system
    }

    init() {
        updatePalette()
        let hasHoskySkin = UserDefaults.standard.bool(forKey: "useHoskyTheme")
        if hasHoskySkin {
            VendanoTheme.shared.currentPalette = .hosky
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(VendanoTheme.shared)
                .preferredColorScheme(resolvedScheme())
                .onChange(of: appearancePrefRaw) { _, _ in
                    updatePalette()
                }
                .onOpenURL { url in
                    handleIncomingLink(url)
                }
        }
    }

    func handleIncomingLink(_ url: URL) {
        if Auth.auth().canHandle(url) { return }

        guard Auth.auth().isSignIn(withEmailLink: url.absoluteString) else { return }

        let email = UserDefaults.standard.string(forKey: "VendanoEmailForLink") ?? ""

        Task {
            do {
                try await FirebaseService.shared.confirmEmailLink(
                    link: url.absoluteString,
                    email: email
                )
                DispatchQueue.main.async {
                    if AppState.shared.displayName.isEmpty {
                        AppState.shared.onboardingStep = .profile
                    } else {
                        NotificationCenter.default.post(
                            name: .didCompleteContactAuth,
                            object: nil
                        )
                    }
                }
            } catch {
                DebugLogger.log("❌ confirmEmailLink failed: \(error)")
            }
        }
    }

    private func resolvedScheme() -> ColorScheme? {
        switch appearancePref {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    private func updatePalette() {
        switch appearancePref {
        case .system:
            let sys = UITraitCollection.current.userInterfaceStyle
            VendanoTheme.shared.currentPalette = (sys == .dark ? .dark : .light)
        case .light:
            VendanoTheme.shared.currentPalette = .light
        case .dark:
            VendanoTheme.shared.currentPalette = .dark
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        let env = AppState.shared.environment
        
        switch env {
        case .appstorereview:
            // Don’t configure Firebase at all
            DebugLogger.log("⚠️ Running in DEMO environment - no Firebase configured")
        case .testnet:
            // Configure with your testnet Firebase plist
            if let filePath = Bundle.main.path(forResource: "GoogleService-Info-Testnet", ofType: "plist"),
               let options = FirebaseOptions(contentsOfFile: filePath) {
                FirebaseApp.configure(options: options)
            }
        case .mainnet:
            FirebaseApp.configure()
            
            authListenerHandle = Auth.auth().addStateDidChangeListener { _, _ in
                FCMTokenBuffer.shared.flushIfPossible()
            }
            
            ReinstallAuthEnforcer.run()

            AnalyticsManager.logOnce("first_open")
            AnalyticsManager.logEvent("general_app_open")

            UNUserNotificationCenter.current().delegate = self
            Messaging.messaging().delegate = self
        }

        return true
    }

    // Called when APNs has assigned the device a token
    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // Called when FCM token is refreshed or initially assigned
    func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }

        if let uid = Auth.auth().currentUser?.uid {
            Task {
                await FirebaseService.shared.setUserData(uid: uid, data: ["fcmToken": fcmToken])
            }
        } else {
            FCMTokenBuffer.shared.pendingToken = fcmToken
        }
    }

    // Handle foreground notification
    func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound]) // show as banner even if app is foreground
    }

    func application(_: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }

        // other handling here (if needed)
        completionHandler(.noData)
    }
}

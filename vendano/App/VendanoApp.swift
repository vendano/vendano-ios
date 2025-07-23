//
//  VendanoApp.swift
//  vendano
//
//  Created by Jeffrey Berthiaume on 6/3/25.
//

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
        guard
            (url.host?.contains("firebaseapp.com") != nil) ||
            (url.host?.contains("vendano.net") != nil),
            url.path.starts(with: "/__/auth/links"),
            let outerComps = URLComponents(url: url, resolvingAgainstBaseURL: false),

            let signedInLink = outerComps.queryItems?
            .first(where: { $0.name == "link" })?
            .value,
            let realLinkURL = URL(string: signedInLink),

            let authComps = URLComponents(url: realLinkURL, resolvingAgainstBaseURL: false),

            let continueStr = authComps.queryItems?
            .first(where: { $0.name == "continueUrl" })?
            .value,
            let continueURL = URL(string: continueStr),

            let contComps = URLComponents(url: continueURL, resolvingAgainstBaseURL: false),
            let email = contComps.queryItems?
            .first(where: { $0.name == "email" })?
            .value,

            Auth.auth().isSignIn(withEmailLink: realLinkURL.absoluteString)
        else {
            return
        }

        Task {
            do {
                try await FirebaseService.shared.confirmEmailLink(
                    link: realLinkURL.absoluteString,
                    email: email
                )
                // At this point both Auth and Firestore have been updated
                DispatchQueue.main.async {
                    if AppState.shared.displayName == "" {
                        AppState.shared.onboardingStep = .profile
                    } else {
                        NotificationCenter.default.post(name: .didCompleteContactAuth, object: nil)
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
    func application(_: UIApplication,
                     didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool
    {
        FirebaseApp.configure()

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        return true
    }

    // Called when APNs has assigned the device a token
    func application(_: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        Messaging.messaging().apnsToken = deviceToken
    }

    // Called when FCM token is refreshed or initially assigned
    func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("FCM token: \(fcmToken)")

        let db = Firestore.firestore()
        let uid = Auth.auth().currentUser?.uid ?? "unknown"
        db.collection("users").document(uid).setData(["fcmToken": fcmToken], merge: true)
    }

    // Handle foreground notification
    func userNotificationCenter(_: UNUserNotificationCenter,
                                willPresent _: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.banner, .sound]) // show as banner even if app is foreground
    }

    func application(_: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }

        // other handling here (if needed)
        completionHandler(.noData)
    }
}

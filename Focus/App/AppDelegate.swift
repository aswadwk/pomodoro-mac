import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        NotificationService.registerCategories()
        Task {
            await NotificationService.requestAuthorization()
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        switch response.actionIdentifier {
        case NotificationAction.startBreak.rawValue:
            NotificationCenter.default.post(name: .focusStartBreakAction, object: nil)
        case NotificationAction.skip.rawValue:
            NotificationCenter.default.post(name: .focusSkipAction, object: nil)
        default:
            break
        }
    }
}

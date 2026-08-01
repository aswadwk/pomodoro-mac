import Foundation
import UserNotifications

enum NotificationAction: String {
    case startBreak = "start-break"
    case skip = "skip"

    var title: String {
        switch self {
        case .startBreak: "Start Break"
        case .skip: "Skip"
        }
    }
}

extension Notification.Name {
    static let focusStartBreakAction = Notification.Name("focus.startBreakAction")
    static let focusSkipAction = Notification.Name("focus.skipAction")
    static let focusSessionCompleted = Notification.Name("focus.sessionCompleted")
}

enum NotificationService {
    private static let categoryIdentifier = "FOCUS_PHASE_DONE"

    static func requestAuthorization() async {
        try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    static func registerCategories() {
        let start = UNNotificationAction(
            identifier: NotificationAction.startBreak.rawValue,
            title: NotificationAction.startBreak.title,
            options: .foreground
        )
        let skip = UNNotificationAction(
            identifier: NotificationAction.skip.rawValue,
            title: NotificationAction.skip.title,
            options: []
        )
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [start, skip],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    static func scheduleBreakReminder() {
        schedule(title: "Focus session complete", body: "Time for a break. Stand up and stretch.")
    }

    static func scheduleFocusReminder() {
        schedule(title: "Break over", body: "Ready for the next focus session?")
    }

    static func removePending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private static func schedule(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

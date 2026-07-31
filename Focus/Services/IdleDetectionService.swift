import CoreGraphics
import Foundation

enum IdleDetectionService {
    static func secondsSinceLastInput() -> TimeInterval {
        let eventTypes: [CGEventType] = [.mouseMoved, .keyDown]
        let idleTimes = eventTypes.map {
            CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0)
        }
        return idleTimes.min() ?? 0
    }
}

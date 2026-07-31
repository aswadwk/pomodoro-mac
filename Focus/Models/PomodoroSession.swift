import Foundation

struct PomodoroSession: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case focus
        case shortBreak
        case longBreak
    }

    let id: UUID
    let kind: Kind
    let date: Date
    let duration: TimeInterval

    init(id: UUID = UUID(), kind: Kind, date: Date, duration: TimeInterval) {
        self.id = id
        self.kind = kind
        self.date = date
        self.duration = duration
    }
}

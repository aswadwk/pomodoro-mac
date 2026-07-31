import AppKit
import Foundation

enum SoundService {
    static func playBreakTime() {
        NSSound(named: "Glass")?.play()
    }

    static func playFocusTime() {
        NSSound(named: "Ping")?.play()
    }
}

import AppKit
import Foundation

@MainActor
enum SoundService {
    static let availableSounds: [String] = {
        let bundleSounds = soundNames(
            Bundle.main.urls(forResourcesWithExtension: "aiff", subdirectory: nil) ?? []
        )
        let systemDir = URL(fileURLWithPath: "/System/Library/Sounds", isDirectory: true)
        let systemSounds = soundNames(
            (try? FileManager.default.contentsOfDirectory(at: systemDir, includingPropertiesForKeys: nil)) ?? []
        )
        return bundleSounds + systemSounds
    }()

    private static func soundNames(_ urls: [URL]) -> [String] {
        urls
            .filter { ["aiff", "caf"].contains($0.pathExtension.lowercased()) }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }

    private static var currentSound: NSSound?

    static func play(_ name: String) {
        stop()
        guard let sound = NSSound(named: name) else { return }
        currentSound = sound
        sound.volume = 1.0
        sound.play()
    }

    static func stop() {
        currentSound?.stop()
        currentSound = nil
    }
}

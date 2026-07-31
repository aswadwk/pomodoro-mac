# AGENTS.md

macOS Pomodoro menu-bar app. Swift 6 + SwiftUI, deployment target macOS 14.0, Swift 6 strict concurrency, Observation (`@Observable`), no tests, no third-party deps.

## Build & run

- `.xcodeproj` is **generated** by XcodeGen from `project.yml` and gitignored. After adding/removing any Swift file you MUST regenerate (`xcodegen generate`) or the build fails with "cannot find type in scope". `make build` / `make dev` regenerate automatically.
- `make dev` = kill running instance → build → `open` the app. `make close` = `killall Focus`.
- App is dockless (`LSUIElement`): no Dock icon, no window. UI lives in the menu bar (`🍅`/timer icon + countdown). To verify it runs: `pgrep -x Focus`; there is never a window to look at.
- Quick compile check: `make build 2>&1 | grep -E 'error:|BUILD'`. Crash reports land in `~/Library/Logs/DiagnosticReports/Focus-*.ips`.
- Signing is ad-hoc (`CODE_SIGN_IDENTITY: "-"`, no team); don't "fix" signing to use a dev team.

## Architecture

- `Focus/App/FocusApp.swift` — entry point: `MenuBarExtra` + `Window` scenes for "statistics" and "settings" (opened via `openWindow(id:)`). Services are created in `init()` and passed down.
- `Focus/Features/Timer/TimerService.swift` — the only state machine: `Phase` (focus/shortBreak/longBreak), `State` (idle/running/paused), 1-second tick task, persists sessions on completion, posts `.focusSessionCompleted`.
- `Focus/Features/Settings/SettingsStore.swift` — settings with `didSet` persistence to `UserDefaults` (raw keys in `PersistenceKey`, `Focus/Services/PersistenceService.swift`). Durations are stored as **minutes** (Int), exposed as `TimeInterval` seconds.
- `Focus/Features/Statistics/StatisticsService.swift` — computed stats from `[PomodoroSession]`; `StatisticsView` refreshes on `.focusSessionCompleted`.
- `Focus/Services/NotificationService.swift` — `UserNotifications`; notification actions post to `NotificationCenter` (`.focusStartBreakAction` / `.focusSkipAction`), observed by `TimerService` via `@objc` selectors.

## Conventions / gotchas

- **`@Environment` does not propagate into MenuBarExtra content/label** — views in the menu bar chain take services as explicit init params (`let timer: TimerService`). Launch crash signature: "No Observable object of type TimerService found". `@Environment` IS used in `Window` scenes (Statistics/Settings).
- `@Observable` bindings in views need `@Bindable var x = x` inside `body` (see `SettingsView`).
- `@MainActor` on all services; new tasks inherit the MainActor.
- Follow the existing layering: Features → Services → Models. Keep `Notification.Name` extensions in `NotificationService.swift`.
- iOS-style framework assumptions don't apply: everything is AppKit/SwiftUI macOS APIs only.

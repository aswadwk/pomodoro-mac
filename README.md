# Focus — Pomodoro Menu Bar App

Aplikasi pomodoro timer untuk macOS yang berjalan di menu bar (dockless). Timer, notifikasi native, idle detection, statistik harian, dan health reminder — dibangun dengan Swift 6 + SwiftUI.

## Requirement

- macOS 14.0+
- Xcode 26+ (untuk Swift 6)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Build & Run

```bash
make build   # generate project + compile
make dev     # build lalu buka (kill instance lama dulu)
make run     # buka app yang sudah di-build
make close   # tutup app
make clean   # hapus build artifacts + project
```

`.xcodeproj` di-generate oleh XcodeGen dari `project.yml` dan tidak di-commit.

## Penggunaan

App berjalan di menu bar kanan atas (ikon ⏱ + waktu tersisa). Klik untuk membuka popover:

- **Start / Pause / Resume / Skip** — kontrol timer
- **Statistics** — sesi hari ini, total waktu fokus/istirahat, produktivitas, grafik 7 hari
- **Settings** — durasi fokus/break, auto-start, idle pause, launch at login, suara & notifikasi

Timer default: 25 menit fokus → 5 menit short break, long break 15 menit setiap 4 sesi. Saat break, popover menampilkan health tips (minum air, 20-20-20, berdiri, stretching).

## Arsitektur

```
Focus/
├── App/                    # Entry point (MenuBarExtra + windows), notification delegate
├── Features/
│   ├── Timer/              # TimerService (state machine), menu bar views
│   ├── Break/              # BreakView + health tips
│   ├── Statistics/         # StatisticsService, StatisticsView (Swift Charts)
│   └── Settings/           # SettingsStore (UserDefaults), SettingsView
├── Services/
│   ├── PersistenceService  # UserDefaults (settings + session history)
│   ├── NotificationService # UserNotifications + notification actions
│   ├── IdleDetectionService# CoreGraphics idle time
│   └── SoundService        # AVFoundation (NSSound)
└── Models/                 # PomodoroSession
```

## Fitur

- Menu bar app (LSUIElement, tanpa Dock icon)
- Countdown realtime di menu bar
- Notifikasi native dengan tombol Start Break / Skip
- Auto-pause saat idle > 60 detik (toggle di Settings)
- Launch at login (SMAppService)
- Statistik harian + grafik 7 hari (Swift Charts)
- Swift 6 strict concurrency, @Observable

## Roadmap

- Global shortcut (⌥⌘S / ⌥⌘P / ⌥⌘B)
- Floating always-on-top timer window
- Widget desktop
- Sync iCloud

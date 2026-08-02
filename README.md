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

## Testing

Stack test: XCTest (tanpa dependency pihak ketiga), dua target test yang didefinisikan di `project.yml`:

- **`FocusTests`** (unit test) — logika bisnis inti: state machine `TimerService`, agregasi `StatisticsService`, default & persistensi `SettingsStore`, dan `PersistenceService` (round-trip, fallback data korup, isolasi suite).
- **`FocusFeatureTests`** (feature test) — alur end-to-end dari perspektif pengguna, dijalankan lewat service asli: start focus → countdown → phase selesai → sesi terekam → statistik ter-update → transisi break, plus alur skip, pause/resume, long break, dan "app relaunch".

```bash
make test          # generate project + jalankan semua test (FocusTests + FocusFeatureTests)
make test-unit     # hanya unit test
make test-feature  # hanya feature test
```

Test deterministik: jam & kalender di-inject (`now`, `calendar`, `idleTime`), tiap test memakai `UserDefaults` suite terisolasi, dan tick timer (biasanya 1 detik) di-disable (`startsTicking: false`) lalu di-drive manual. Berjalan di CI via GitHub Actions (`.github/workflows/ci.yml`, runner macOS).

Catatan: `FocusTests`/`FocusFeatureTests` memakai test host `Focus.app`; saat test berjalan, suara/notifikasi/idle detection di-disable lewat settings test agar tidak ada efek samping.

## GitHub Actions

Semua workflow di `.github/workflows/` memakai action resmi dari `actions/*` yang di-pin ke **versi patch penuh** (misal `actions/checkout@v7.0.1`), bukan branch (`@main`/`@master`) atau tag ambigu — untuk reproducibilitas maksimal antar run.

| Action | Versi ter-pin |
| --- | --- |
| `actions/checkout` | `v7.0.1` |
| `actions/upload-artifact` | `v7.0.1` |
| `actions/download-artifact` | `v8.0.1` |
| `actions/github-script` | `v9.0.0` |

**Proses pembaruan rutin:** cek halaman Releases tiap action (misal `https://github.com/actions/checkout/releases`) untuk versi terbaru, lalu:

1. Bump pin di `ci.yml` / `build.yml` ke versi patch terbaru (misal `v7.0.1` → `v7.0.2`).
2. Jalankan workflow (push ke branch PR) dan pastikan semua job hijau.
3. Baca release notes sebelum menaikkan versi mayor — API action bisa berubah antar mayor.

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

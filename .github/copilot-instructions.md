# Chinese Chess (Cờ Tướng) — Project Guidelines

## Project Overview

Flutter Chinese Chess app supporting **Android, iOS, Web, Windows, Linux, macOS**.

- **Entry point**: `lib/main.dart`
- **Central game state**: `GameManager` singleton (`lib/models/game_manager.dart`) — event bus via `StreamController<GameEvent>`
- **Chess rules**: delegated to `cchess: ^0.0.7` pub package (do NOT reimplement move validation)
- **AI engine**: federated plugin (`plugins/engine/`) — ElEEye (UCCI) and Pikafish (UCI/NNUE) via stdin/stdout; Android is currently a stub → uses server-side API
- **Navigation**: currently imperative `Navigator.push` — being migrated to `go_router`
- **No state management library** — singleton + event bus pattern throughout

## Architecture

```
lib/
  main.dart              # App entry point
  game_board.dart        # Main game screen (being split into screens/)
  setting.dart           # Settings screen
  global.dart            # Global constants/config
  theme.dart             # App theme
  models/                # GameManager, GameSetting, ChessSkin, Players, Events
  driver/                # DriverUser (human), DriverRobot (AI), DriverOnline (stub→impl)
  components/            # Chess board widgets, piece animations, player panels
  widgets/               # Reusable UI widgets
  screens/               # New screens (created during Phase 1 migration)
  services/              # App services (ads, auth, API, realtime, matchmaking)
  config/                # AppConfig (API base URL, WS URL from --dart-define)
  l10n/                  # Localization: en, vi, zh
  utils/
  foundation/
plugins/
  engine/                # Federated plugin facade
  engine_interface/      # Abstract EngineInterface + UCI/UCCI protocol logic
  engine_android/        # Android — HTTP API to server-side engine (Phase 6)
  engine_darwin/         # iOS/macOS — native binary
  engine_linux/          # Linux — native binary
  engine_windows/        # Windows — native binary
  engine_web/            # Web — pure Dart cchess_engine
```

## Key Patterns

- **GameManager events**: use `gamer.on<EventType>(handler)` / `gamer.off<EventType>(handler)` in `initState`/`dispose`
- **Board coordinates**: `ChessPos(row, col)` — row 0–9, col 0–8; use `ChessRule` from `cchess` for validity
- **Engine communication**: UCI `position fen <fen> moves <move...>` then `go depth <n>` → parse `bestmove <move>`
- **Skin system**: piece/board images from `assets/skins/woods/config.json`; access via `GameManager.instance.skin`
- **Localization**: `context.l10n.keyName` (extension in `lib/utils/core.dart`)
- **Responsive**: `MediaQuery.size.width < 980` → mobile layout; `≥ 980` → desktop side-by-side layout

## Build & Test

```bash
flutter pub get
flutter test
flutter run
flutter build appbundle --split-per-abi   # Android release
flutter build ipa                          # iOS release
```

## Roadmap

Full 8-phase implementation plan: **see `docs/ROADMAP.md`**

Current phase status is tracked there with checkboxes. Always consult it before starting work on a new feature to understand scope, affected files, and phase dependencies.

# Chinese Chess App — Implementation Roadmap

> Last updated: 2026-04-08

## Progress Tracker

- [x] Phase 1 — UI/UX: Navigation & Screens
- [ ] Phase 2 — Ads: Google AdMob
- [ ] Phase 3 — Core Logic: Timer & Edge Cases
- [ ] Phase 4 — Backend & Matchmaking
- [ ] Phase 5 — Live Match Feature
- [ ] Phase 6 — AI Engine: Android & Server-side
- [ ] Phase 7 — QA/QC
- [ ] Phase 8 — Store Release

---

## Decisions

| Topic | Decision |
|---|---|
| Navigation | Migrate to `go_router` (currently imperative push/pop) |
| Ads | Google AdMob (`google_mobile_ads`) |
| Android AI | Server-side API call (`POST /api/engine/bestmove`), pure-Dart heuristic as offline fallback |
| Backend tech | TBD — Flutter service layer is interface-based, backend can be swapped |
| Out of scope | Desktop-specific live match, macOS/Linux store publishing, ELO formula (backend concern) |

---

## Baseline — Current State

- **3 screens**: `GameBoard` (home+game merged), `SettingPage`, `EditFen`
- **Navigation**: Imperative `Navigator.push/pop` — no named routes
- **Game logic**: `cchess` package + `GameManager` singleton + event bus
- **AI**: Federated plugin (ElEEye/Pikafish via UCI/UCCI) — desktop/iOS works; **Android stub** (`supported = []`)
- **Ads**: None
- **Backend/Networking**: None (`DriverOnline` = all `UnimplementedError`)
- **Live Match**: Not implemented (shows "Feature not available" toast)
- **Timer**: No countdown timer
- **Key deps**: cchess, audioplayers, shared_preferences, window_manager, file_picker, shirne_dialog

---

## Phase 1 — UI/UX: Navigation & Screens

**Status**: `[x] Completed — 2026-04-08`

### Steps

1. Add `go_router: ^14.x` to `pubspec.yaml`
2. Create route config `lib/router.dart` — define 4 named routes:
   - `/` → `HomeScreen`
   - `/game` → `BoardScreen` (receives `PlayMode` as extra)
   - `/settings` → `SettingPage` (existing `lib/setting.dart`)
   - `/live` → `LiveMatchScreen` (new)
3. **`lib/screens/home_screen.dart`**:
   - Extract mode-selector logic from `_GameBoardState.selectMode()` in `lib/game_board.dart`
   - 3 buttons: vs Robot, Online, Free Play → `context.go('/game', extra: mode)`
   - App title, settings icon → `context.push('/settings')`
   - Live Match button → `context.push('/live')`
4. **`lib/screens/board_screen.dart`**:
   - Refactor `GameBoard` — keep `PlayPage`, `Chess`, player panels
   - Remove mode-selector logic (moved to HomeScreen)
   - Keep Drawer→Settings and AppBar→EditFen flows
   - Receives `PlayMode` from router `extra`
5. **`lib/screens/live_match_screen.dart`**:
   - Scaffold with card list (stub data; real data in Phase 5)
   - Placeholder `MiniBoard` widget per card
6. Update `lib/main.dart`:
   - Replace `MaterialApp(home: GameWrapper(...))` with `MaterialApp.router(routerConfig: appRouter)`
   - `GameWrapper` becomes `ShellRoute` ancestor
7. Add l10n keys to `lib/l10n/app_en.arb`, `app_vi.arb`, `app_zh.arb`: `liveMatch`, `vsRobot`, `freePlay`

### Files Modified
- `pubspec.yaml` — add go_router
- `lib/main.dart` — router setup
- `lib/game_board.dart` — remove home logic, keep game layout only
- `lib/setting.dart` — minor: accept go_router back navigation
- `lib/l10n/app_*.arb` — new keys

### Files Created
- `lib/router.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/board_screen.dart`
- `lib/screens/live_match_screen.dart`

### Verification
Navigate all 4 routes on physical device; back button works correctly.

---

## Phase 2 — Ads: Google AdMob

**Status**: `[ ] Not started`

### Goal
Integrate AdMob banners (top/bottom) and interstitial triggered by play count.

### Steps

1. Add `google_mobile_ads: ^5.x` to `pubspec.yaml`
2. Configure native platform:
   - `android/app/src/main/AndroidManifest.xml` — `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" .../>`
   - `ios/Runner/Info.plist` — `GADApplicationIdentifier` key
3. **`lib/services/ads_service.dart`** — singleton `AdsService`:
   - `init()` → `MobileAds.instance.initialize()`
   - `loadBanner(position: top|bottom)` → returns `BannerAd`
   - `loadInterstitial()` → preloads `InterstitialAd`
   - `showInterstitial()` → shows if loaded + reloads
   - Play-count state machine: counter in `SharedPreferences`; trigger interstitial every N games (default=3)
4. **`lib/widgets/banner_ad_widget.dart`** — wraps `AdWidget` with fixed height container; handles `dispose()`
5. Integrate into `BoardScreen`: add `BannerAdWidget` top + bottom
6. Call `AdsService.instance.onGameStart()` from `GameManager.newGame()`
7. Initialize `AdsService` in `main.dart` before `runApp()`

### Files Modified
- `pubspec.yaml`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `lib/main.dart`
- `lib/models/game_manager.dart` — add ads hook
- `lib/screens/board_screen.dart` — add BannerAdWidgets

### Files Created
- `lib/services/ads_service.dart`
- `lib/widgets/banner_ad_widget.dart`

### Verification
Ads load in debug mode (test IDs); interstitial fires exactly every 3 games.

---

## Phase 3 — Core Logic: Timer & Edge Cases

**Status**: `[ ] Not started`

### Goal
Add per-player countdown timer; expand test coverage for edge cases.

### Steps

1. **`lib/models/game_timer.dart`** — `GameTimer` class:
   - Per-player `Duration` countdown (configurable initial time)
   - `start()`, `pause()`, `resume()`, `reset()`, `dispose()`
   - Broadcasts on `StreamController<Duration>` for UI
   - On reach zero → fires `GameResultEvent` (timeout loss) via `GameManager`
2. Integrate into `GameManager`:
   - Two `GameTimer` instances (red, black)
   - `switchPlayer()`: pause current, start next
   - `newGame()`: reset both
   - `GameResultEvent`: stop both
   - Duration from `GameSetting` new field `timeLimit`
3. **`lib/widgets/player_timer_widget.dart`** — countdown display, turns red when < 10s
4. Add timer display to `PlayPlayer` / `PlaySinglePlayer` panels
5. Add `timeLimit` option to `SettingPage`: off / 3 min / 5 min / 10 min
6. Expand `test/model_test.dart`:
   - Check detection (Tướng bị chiếu)
   - Cannon capture through exactly one piece
   - Horse L-shape block detection
   - 3-fold repetition detection
   - Timer expiry → result

### Files Modified
- `lib/models/game_manager.dart`
- `lib/models/game_setting.dart`
- `lib/components/play_player.dart`
- `lib/setting.dart`
- `test/model_test.dart`

### Files Created
- `lib/models/game_timer.dart`
- `lib/widgets/player_timer_widget.dart`

### Verification
Timer counts down, pauses on turn switch; timeout triggers game end.

---

## Phase 4 — Backend & Matchmaking

**Status**: `[ ] Not started`

### Goal
Implement Flutter-side auth, API, real-time channel, matchmaking behind abstract interfaces (backend tech TBD, swappable).

### Steps

**4.1 — Data models**
- `lib/models/user_model.dart` — `UserModel {id, username, eloRating, avatarUrl}`
- `lib/models/room_model.dart` — `RoomModel {id, status, playerRed, playerBlack, currentFen, moves[]}`
- `lib/models/match_model.dart` — `MatchModel {id, roomId, startTime, result}`

**4.2 — Abstract interfaces** (`lib/services/interfaces/`)
- `auth_interface.dart` — `IAuthService {login, register, logout, currentUser, tokenStream}`
- `api_interface.dart` — `IApiService {getRooms, getRoom, createRoom, joinRoom, leaveRoom}`
- `realtime_interface.dart` — `IRealtimeService {connectRoom, disconnectRoom, movesStream, roomStateStream, sendMove}`

**4.3 — Concrete implementations**
- `lib/services/auth_service.dart` — HTTP `/auth/login`, `/auth/register`; token in `SharedPreferences`
- `lib/services/api_service.dart` — `dio` package; base URL from `AppConfig`
- `lib/services/realtime_service.dart` — `web_socket_channel` package

**4.4 — Config**: `lib/config/app_config.dart` — `apiBaseUrl`, `wsBaseUrl` from `--dart-define`

**4.5 — Matchmaking**
- `lib/services/matchmaking_service.dart`:
  - `joinQueue()` / `leaveQueue()` → POST endpoints
  - Subscribes to matchmaking events
  - Timeout → fallback to bot match

**4.6 — DriverOnline** (`lib/driver/driver_online.dart`): full implementation replacing `UnimplementedError`

**4.7 — Auth UI**
- `lib/screens/login_screen.dart` — login / register form
- `lib/screens/profile_screen.dart` — username, ELO rating
- Guard: if `PlayMode.online` and not logged in → redirect to login

### New Deps
- `dio: ^5.x`
- `web_socket_channel: ^3.x`

### Files Created
- `lib/models/user_model.dart`, `room_model.dart`, `match_model.dart`
- `lib/services/interfaces/` (3 files)
- `lib/services/auth_service.dart`, `api_service.dart`, `realtime_service.dart`, `matchmaking_service.dart`
- `lib/config/app_config.dart`
- `lib/screens/login_screen.dart`, `profile_screen.dart`

### Files Modified
- `lib/driver/driver_online.dart`
- `lib/router.dart`
- `pubspec.yaml`

### Verification
Login/register roundtrip with test backend; online game moves sync between 2 clients.

---

## Phase 5 — Live Match Feature

**Status**: `[ ] Not started`
**Depends on**: Phase 4

### Goal
Display up to 10 live matches in real time; auto-fill with Bot vs Bot when fewer than 10 real games exist.

### Steps

1. **`lib/services/live_match_service.dart`**:
   - Subscribe to `IRealtimeService` "active rooms" channel
   - Maintain `List<RoomModel>` (max 10), fill remainder with bot simulations
   - Expose `Stream<List<RoomModel>> liveRoomsStream`
2. **`lib/widgets/mini_chess_board.dart`**: read-only board from FEN, reuses `ChessSkin`, `AnimatedSwitcher` on move
3. **`lib/widgets/live_match_card.dart`**: `MiniChessBoard` + player names + move count + elapsed time; `onTap` → spectator view
4. **`LiveMatchScreen`** (scaffolded Phase 1) — full implementation with `StreamBuilder` + `ListView.builder` + pull-to-refresh
5. **Spectator mode**: extend `BoardScreen` with `isSpectator: bool` — disable interactions, receive live FEN
6. **`lib/services/bot_simulation_service.dart`**: synthetic `RoomModel` entries using two `DriverRobot` instances; push FEN snapshots to stream

### Files Created
- `lib/services/live_match_service.dart`
- `lib/services/bot_simulation_service.dart`
- `lib/widgets/mini_chess_board.dart`
- `lib/widgets/live_match_card.dart`

### Files Modified
- `lib/screens/live_match_screen.dart`
- `lib/screens/board_screen.dart`

### Verification
Live list shows ≥1 real match + fills to 10 with bots; FEN updates render in real time.

---

## Phase 6 — AI Engine: Android & Server-side

**Status**: `[ ] Not started`

### Goal
Fix Android AI stub. Android calls backend API for best move; pure-Dart heuristic as offline fallback.

### Backend API Contract (for backend team)

```
POST /api/engine/bestmove
Request:  { fen: string, moves: string[], level: 10|11|12, timeMs: int }
Response: { bestmove: string, info?: string }
Backend runs ElEEye or Pikafish server-side.
```

### Level → Depth/Timeout Mapping

| Level | Depth | Timeout |
|---|---|---|
| 10 (Beginner) | 5 | 500ms |
| 11 (Intermediate) | 8 | 1500ms |
| 12 (Master) | 12 | 3000ms |

### Steps

1. **`lib/services/engine_api_service.dart`**: HTTP client for `/api/engine/bestmove`; level→depth/time mapping
2. **`plugins/engine_android/lib/engine_android.dart`**:
   - Override `supported` → `[EngineInfo.eleeye, EngineInfo.pikafish]`
   - Override `requestMove()` → calls `EngineApiService`
   - Timeout + retry (max 2 attempts)
   - Offline: fall back to pure-Dart heuristic in `DriverRobot`

### Files Modified
- `plugins/engine_android/lib/engine_android.dart`
- `plugins/engine_interface/lib/src/engine_interface.dart`

### Files Created
- `lib/services/engine_api_service.dart`

### Verification
Android bot responds within 5s on level 10/11; graceful fallback when offline.

---

## Phase 7 — QA/QC

**Status**: `[ ] Not started`

### Steps

1. **`test/matchmaking_test.dart`**: mock `IRealtimeService` + `IApiService`; 2-user queue → match formed; timeout → bot fallback
2. **Layout tests**: widths 360/768/980/1280px; verify `GameWrapper` scale factor
3. **`test/model_test.dart`** — chess logic regression: cannon capture, horse block, elephant river, long check, PGN replay
4. **`test/performance_test.dart`**: Dart heuristic < 200ms; Android HTTP API < 5s
5. **Memory audit**: all `StreamController.close()` in `dispose()`; `GameTimer.dispose()` on screen pop

---

## Phase 8 — Store Release

**Status**: `[ ] Not started`

### Steps

1. **Android signing**: `android/key.properties` + keystore; `build.gradle.kts` release `signingConfig`
2. **Android manifest**: permissions review, remove unused
3. **iOS**: Xcode signing, bundle ID, entitlements
4. **Build**: `flutter build appbundle --split-per-abi`
5. **Privacy policy**: hosted URL → `Info.plist` + `AndroidManifest.xml` (required for AdMob)
6. **GDPR consent dialog** for EU users; `app_tracking_transparency` for iOS 14+
7. **Store metadata**: screenshots (6 sizes), descriptions en/vi/zh, feature graphic
8. **Pre-launch checklist**: no crash on cold start, graceful degradation when ads fail / backend offline

---

## Key Files Reference

| File | Phase | Role |
|---|---|---|
| `lib/main.dart` | 1, 2 | App entry — router + AdMob init |
| `lib/game_board.dart` | 1 | Split into HomeScreen + BoardScreen |
| `lib/setting.dart` | 1, 3 | Add timeLimit option |
| `lib/models/game_manager.dart` | 2, 3 | Add ads hook + timer |
| `lib/driver/driver_online.dart` | 4 | Full implementation |
| `plugins/engine_android/lib/engine_android.dart` | 6 | HTTP engine impl |
| `pubspec.yaml` | 1, 2, 4 | New deps |
| `android/app/src/main/AndroidManifest.xml` | 2, 8 | AdMob ID, permissions |
| `ios/Runner/Info.plist` | 2, 8 | AdMob ID, ATT |
| `test/model_test.dart` | 3, 7 | Chess logic tests |

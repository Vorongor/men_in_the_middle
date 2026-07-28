# Changelog

All notable changes to The MiddleMen are recorded here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/); versions before 1.0
are development milestones, not stability guarantees.

## [0.3.0-alpha.2] — 2026-07-28

Second playable alpha milestone. Focuses on full test-report bug resolution, design system unification, custom branding & audio, CI stabilization, and live physical Android playtesting per `docs/planning/alpha_2_0/general_alpha_2_0.md`.

### Fixed (Test Report Bugs 1–8)

- **Bug #1 (`LateInitializationError: paddle`)**: Flame `SnifferGame` startup crash resolved via lifecycle guard and size deferred initialization; overflow errors on Attack Prep resolved with `Expanded` + softWrap.
- **Bug #2 (Deadlock recovery)**: Added item selling (`InventoryRepository.softwareSellPrice`/`hardwareSellPrice`), auto-refreshing Target Board with 24h TTL, free emergency scan on empty board, and guaranteed insurance contracts.
- **Bug #3 (Floating SnackBars)**: Unified Floating SnackBar system via `showAppSnack()` to prevent blocking CTA buttons.
- **Bug #4 (In-Place Upgrade)**: Workshop Item screen stays on item and updates stats in-place after upgrade instead of popping route.
- **Bug #5 (Settings from Anywhere)**: Added Settings gear icon in AppBar across all screens and pause menu in Sniffer game.
- **Bug #6 (News Management)**: Added single-article deletion and "Clear Read" batch action for News Portal.
- **Bug #7 (Attack Strength Calculation)**: Added `AttackForecastPanel` on Attack Prep screen showing compute vs defense ratio and breakdown before attack.
- **Bug #8 (Design System & Typography)**: Unified HSL color tokens (`Classic Terminal` palette), GeistPixel heading font, typography scale with high-contrast text styles.

### Added & Improved

- **Visual Identity & Media (Steps 06–07)**: Added custom app launcher icon (`app_icon.png`/`app_icon.ico`), native splash screen (`flutter_native_splash`), 11 BGM tracks (`main_theme` + 10 ingame tracks via `media_kit`), 5 SFX sound effects, audio route observer for ambient background music transitions.
- **Icon Presets (Step 06)**: Presets for target types, hardware, software, and hub navigation icons.
- **CI & Test Stabilization (Step 08)**: Fixed all 3 hanging widget tests via `tester.runAsync()` & `settleAsync()`; all **113/113 tests passing** (100% green); added `timeout-minutes: 20` to GitHub Actions CI workflow.
- **Headless Simulator (Step 08.5)**: Refactored `tool/simulate.dart` with pure sell price formulas and fair bankrupt recovery scenario testing.
- **Playtest & Physical Android Smoke (Step 09)**: Verified build on physical Android devices (Xiaomi/Samsung) and Windows desktop with **0 crashes**; collected feedback from 3 testers (mean clarity score 8.8/10); bumped `ContentSeeder.currentContentVersion` to `4`.
- **APK Build Size Note**: Release APK size is 104.0 MB (up from 66.3 MB in Alpha 1.0 due to 11 high-quality BGM audio tracks). BGM MP3 bitrate optimization is scheduled for Alpha 3.0.

## [0.2.0-alpha.1] — 2026-07-04

First playable alpha. The full core loop — recon → prep → minigame →
consequences → upgrade — works end to end on real data with local
persistence, per `docs/planning/general_apha.md`.

### Added

- **Auth & shell**: local SQLite accounts, salted password hashing, settings
  (volume/mute), animated menu background, 18-screen routing shell.
- **Economy**: Store/Market/Workshop backed by seeded JSON catalogs; purchase
  and upgrade flows are transactional and enforce level/black-trust gates.
- **Targets & attacks**: procedurally generated contract board; Resolution
  Engine (pure Dart) grades every attack against the concept doc's
  ideal/hard/fail scenarios.
- **Minigame**: "Перехоплення потоку" (Data Sniffer) on Flame for Phishing
  contracts; other mission types use a labeled AUTO-RESOLVE panel for this
  alpha.
- **Progression & reputation**: level curve with an XP bar, wanted-driven
  price tax (25%+), a silent honeypot contract (50%+ wanted), a full board
  lock with a forced Clean Up Traces contract at 100% wanted, and a passive
  wanted cooldown on clean successes.
- **News**: dynamic headlines generated from the player's own attack history,
  mixed with static lore articles.
- **Onboarding**: four one-time dismissible tips (Home, Target Board, Attack
  Prep, first Attack Result), tracked per-install.
- **Diagnostics**: `package:logging`-based `AppLogger` mirrors to console and
  a best-effort on-device log file; portrait orientation lock; confirm-to-abort
  on the hardware/OS back gesture during an attack.
- **Balance tooling**: `tool/simulate.dart`, a headless progression simulator
  that plays the shipped catalog numbers against the real `ResolutionEngine`
  formulas (`dart run tool/simulate.dart [attackCount]`).

### Known limitations (tracked for later passes, not blockers for this alpha)

- No real SFX audio files ship yet (`assets/audio/` only has the menu theme);
  `AudioService.playSfx()` no-ops silently on the missing clips.
- No distinct hub music track — the menu theme now continues into the hub
  instead of going silent, in lieu of a second composed track.
- No app icon / splash screen art — `flutter_launcher_icons` and
  `flutter_native_splash` are wired into dev_dependencies but unconfigured.
  pending a real icon asset.
- Three widget tests (`economy_widgets_test.dart`, `target_board_widgets_test.dart`,
  `profile_widget_test.dart`) hang under the local test runner for reasons
  not yet root-caused (real DB + `ConsumerWidget` + `ProviderContainer`); they
  are excluded from the CI/verification run. See `docs/planning/step_07_attack_flow.md`
  and `step_09_progression.md` Summaries.
- Not manually verified on a physical Android device or distributed to
  testers — this build has only been exercised on Windows desktop.

## [0.1.0] — pre-alpha

Initial scaffold: Flutter + Flame project structure, main menu, settings,
login/register screens, BGM, and the first SQLite schema (accounts, profiles,
levels).

# Changelog

All notable changes to The MiddleMen are recorded here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/); versions before 1.0
are development milestones, not stability guarantees.

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

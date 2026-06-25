# Screen Map — The MiddleMen

## Overview

```
[Screen 1 · Main Menu]
        │
        ├── Settings ──► [Screen 1.2 · Settings]
        │                        │
        │                       Back
        │                        │
        ├── Start ────► [Screen 2 · Auth]
        │                        │
        │              ┌─────────┴──────────┐
        │            Enter               First In
        │              │                     │
        │              └─────────┬───────────┘
        │                        ▼
        │               [Screen 3 · Dashboard]
        │
        └── Exit ─────► (app closes)
```

---

## Screen 1 — Main Menu

| Property | Value |
|---|---|
| Route | `/` |
| Class | `HomeScreen` |
| File | `lib/screens/home_screen.dart` |

**Background:** Animated (`matrix_bg.mp4`) with static fallback (`home-bg-techno.jpg`).  
**Music:** BGM starts on app launch, plays through Screens 1 and 2.

### Elements
| Element | Type | Behaviour |
|---|---|---|
| "The MiddleMen" | Title (Cinzel 42px) | Static display |
| Start | Button | Navigates to Screen 2 (`/login`) |
| Settings | Button | Navigates to Screen 1.2 (`/settings`) |
| Exit | Button | `SystemNavigator.pop()` — closes the app |

---

## Screen 1.2 — Settings

| Property | Value |
|---|---|
| Route | `/settings` |
| Class | `SettingsScreen` |
| File | `lib/screens/settings_screen.dart` |

**Background:** Same animated/fallback stack as Screen 1.  
**Persistence:** All values saved to `shared_preferences` on Back.

### Elements
| Element | Type | Key | Default |
|---|---|---|---|
| Mute All | Toggle button (filled=on) | `mute_all` | false |
| General Volume | Slider 0–1 | `general_volume` | 1.0 |
| Music Volume | Slider 0–1 | `music_volume` | 1.0 |
| Effects Volume | Slider 0–1 | `effects_volume` | 1.0 |
| Back | Button | — | Saves settings, applies BGM volume, pops |

**Volume formula:** `effectiveMusicVolume = muteAll ? 0 : (general × music)`

---

## Screen 2 — Auth (Login / Register)

| Property | Value |
|---|---|
| Route | `/login` |
| Class | `LoginScreen` |
| File | `lib/screens/login_screen.dart` |

**Background:** Animated (`matrix_bg.mp4`) with static fallback (`login.jpg`).  
**Music:** BGM continues from Screen 1. Stops on successful auth.

### Flows
#### Enter (login)
1. SHA-256 hash the password field
2. Query `accounts JOIN profiles JOIN levels WHERE pseudo=? AND pass=?`
3. **Success** → stop BGM → navigate to Screen 3 with `AccountWithProfile`
4. **Wrong credentials** → SnackBar `CODE-400, WRONG CREDENTIALS!`
5. **DB error** → SnackBar `CODE-500, DB FAIL!`

#### First In (register)
1. SHA-256 hash the password field
2. Pick a random legend from `assets/data/legends.json`
3. Insert `profiles` row (all defaults, random legend, level_id=1, experience=0)
4. Insert `accounts` row (pseudo, passHash, profile_id)
5. **Success** → stop BGM → navigate to Screen 3 with `AccountWithProfile`
6. **Duplicate pseudo / DB error** → SnackBar `CODE-500, DB FAIL!`

### Elements
| Element | Type |
|---|---|
| Pseudo | Text input |
| Pass | Password input (obscured) |
| Enter | Action button (login flow) |
| First In | Action button (register flow) |

---

## Screen 3 — Dashboard (Agent Profile)

| Property | Value |
|---|---|
| Route | `/dashboard` |
| Class | `DashboardScreen` |
| File | `lib/screens/dashboard_screen.dart` |

**Background:** Solid black.  
**Music:** Silent (BGM stopped on entry).  
**Data source:** `AccountWithProfile` passed as route argument from Screen 2.

### Sections & Fields
| Section | Field | Source |
|---|---|---|
| AGENT PROFILE | ID | `account.id` |
| | Handle | `account.pseudo` |
| | Rank | `level.name` + level id (e.g. "Mouse · Lv.1") |
| | Experience | `profile.experience` |
| CAPABILITIES | Software Power | `profile.softwarePower` |
| | Hardware Power | `profile.hardwarePower` |
| REPUTATION | Rating | `profile.rating` |
| | Karma | `profile.karma` (1–100) |
| | Wanted | `profile.wanted` (1–100) |
| | Popularity | `profile.popularity` |
| | Black Trust | `profile.blackTrust` (1–100) |
| LEGEND | Legend text | `profile.legend` (full paragraph, italic) |

---

## Screen 4 — Game *(planned)*

| Property | Value |
|---|---|
| Route | `/game` |
| Class | `GameScreen` / `MiddlemenGame` |
| File | `lib/screens/game_screen.dart`, `lib/game/middlemen_game.dart` |

**Status:** Stub only. `MiddlemenGame` extends `FlameGame` with empty `onLoad()`.  
**Entry:** Will be accessible from the Dashboard or a future lobby screen.

---

## Data Models

| Model | File | Used by |
|---|---|---|
| `Account` | `lib/models/account.dart` | DB, Auth |
| `Profile` | `lib/models/profile.dart` | DB, Dashboard |
| `Level` | `lib/models/level.dart` | DB, Dashboard |
| `AccountWithProfile` | `lib/models/account_with_profile.dart` | Auth → Dashboard |

## Services

| Service | File | Responsibility |
|---|---|---|
| `DatabaseHelper` | `lib/db/database_helper.dart` | SQLite singleton, all queries |
| `AudioService` | `lib/services/audio_service.dart` | BGM start/stop/volume |
| `SettingsService` | `lib/services/settings_service.dart` | shared_preferences load/save |

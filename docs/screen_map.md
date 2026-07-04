# Screen Map — The MiddleMen

## Screen Map

| screen num  | screen name              | description                                                                   |
| ----------- | ------------------------ | ----------------------------------------------------------------------------- |
| Screen 1    | Main Menu                | Game entry point                                                              |
| Screen 1.2  | Settings                 | Game settings                                                                 |
| Screen 2    | Auth                     | Auth point. Choose/Create acc                                                 |
| Screen 3    | Home Page                | In game home page                                                             |
| Screen 4    | Profile                  | Page with user stats                                                          |
| Screen 5.1  | Target Board             | Page with list of targets                                                     |
| Screen 5.2  | Target Deatail           | Page with detail target info                                                  |
| Screen 6.1  | Grey store               | Page with list of software Items                                              |
| Screen 6.2  | Store Item               | Page with detail info about software item                                     |
| Screen 7.1  | Atack preparation screen | Page with preparation info about hacker atack                                 |
| Screen 7.2  | Atack screen             | Page with minigame for bonuses to hacker atack                                |
| Screen 7.3  | Atack result screen      | Page with result info about hacker atack                                      |
| Screen 8.1  | Hardware Market          | Page with list of software Items                                              |
| Screen 8.2  | Hard ware Item           | Page with detail info about software item                                     |
| Screen 9.1  | Workshop                 | Page with list of user owned Items hardware + software                        |
| Screen 9.2  | Workshop Item updating   | Page with detail info user owned Item hardware or software + updating options |
| Screen 10.1 | News Portal              | Page with list of news                                                        |
| Screen 10.2 | Dataile about news       | Page with detail info about news article                                      |

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
        │               [Screen 3 · Home Page ]
        │              ┌─────────┴──────────────┬────────────────────────┬────────────────────────┬────────────────────────┬─────────────────────────┐
        |    "Block with user info"      "Block target board"   "Icon in icons block"    "Icon in icons block"    "Icon in icons block"     "Icon in icons block"
        │     "top of screen 15%"       "middle of screen 50%"  "buttom of screen 35%"   "buttom of screen 35%"  "buttom of screen 35%"     "buttom of screen 35%"
        │              ▼                        ▼                        ▼                        ▼                        ▼                         ▼
        │      [Screen 4 - Profile]    [Screen 5.1 - Target]    [Screen 6.1 - Store]      [Screen 8.1 - Market]      [Screen 9.1 - Workshop]   [Screen 10.1 - News Portal]
        │                                       ▼                        ▼                        ▼                        ▼                         ▼
        │                           [Screen 5.2 - Target info] [Screen 6.2 - Store Item] [Screen 8.2 - Market Item] [Screen 9.2 - Workshop Item] [Screen 10.2 - News Item]
        │                                       ▼
        │                     [Screen 7.1 - Atack preparation screen]
        │                                       ▼
        │                         [Screen 7.2 - Atack screen]
        │                                       ▼
        │                     [Screen 7.3 - Atack result screen]
        │
        │
        │
        └── Exit ─────► (app closes)
```

---

## Screen 1 — Main Menu

| Property | Value                          |
| -------- | ------------------------------ |
| Route    | `/`                            |
| Class    | `HomeScreen`                   |
| File     | `lib/screens/home_screen.dart` |

**Background:** Animated (`matrix_bg.mp4`) with static fallback (`home-bg-techno.jpg`).  
**Music:** BGM starts on app launch, plays through Screens 1 and 2.

### Elements

| Element         | Type                | Behaviour                                |
| --------------- | ------------------- | ---------------------------------------- |
| "The MiddleMen" | Title (Cinzel 42px) | Static display                           |
| Start           | Button              | Navigates to Screen 2 (`/login`)         |
| Settings        | Button              | Navigates to Screen 1.2 (`/settings`)    |
| Exit            | Button              | `SystemNavigator.pop()` — closes the app |

---

## Screen 1.2 — Settings

| Property | Value                              |
| -------- | ---------------------------------- |
| Route    | `/settings`                        |
| Class    | `SettingsScreen`                   |
| File     | `lib/screens/settings_screen.dart` |

**Background:** Same animated/fallback stack as Screen 1.  
**Persistence:** All values saved to `shared_preferences` on Back.

### Elements

| Element        | Type                      | Key              | Default                                  |
| -------------- | ------------------------- | ---------------- | ---------------------------------------- |
| Mute All       | Toggle button (filled=on) | `mute_all`       | false                                    |
| General Volume | Slider 0–1                | `general_volume` | 1.0                                      |
| Music Volume   | Slider 0–1                | `music_volume`   | 1.0                                      |
| Effects Volume | Slider 0–1                | `effects_volume` | 1.0                                      |
| Back           | Button                    | —                | Saves settings, applies BGM volume, pops |

**Volume formula:** `effectiveMusicVolume = muteAll ? 0 : (general × music)`

---

## Screen 2 — Auth (Login / Register)

| Property | Value                           |
| -------- | ------------------------------- |
| Route    | `/login`                        |
| Class    | `LoginScreen`                   |
| File     | `lib/screens/login_screen.dart` |

**Background:** Animated (`matrix_bg.mp4`) with static fallback (`login.jpg`).  
**Music:** BGM continues from Screen 1 (Step 10: no longer stopped on auth — it
keeps playing into the hub since there's no distinct hub track yet).

### Flows

#### Enter (login)

1. Query `accounts JOIN profiles JOIN levels WHERE pseudo=? AND salted pass hash=?`
2. **Success** → navigate to Screen 3 (session now lives in `playerSessionProvider`, not a route argument)
3. **Wrong credentials** → SnackBar `CODE-400, WRONG CREDENTIALS!`
4. **DB error** → SnackBar `CODE-500, DB FAIL!`

#### First In (register)

1. Pick a random legend from `assets/data/legends.json`
2. Insert `profiles` row (starter epts/software/hardware, random legend, level_id=1, experience=0)
3. Insert `accounts` row (pseudo, salted pass hash, profile_id)
4. **Success** → navigate to Screen 3
5. **Duplicate pseudo / DB error** → SnackBar `CODE-500, DB FAIL!`

### Elements

| Element  | Type                          |
| -------- | ----------------------------- |
| Pseudo   | Text input                    |
| Pass     | Password input (obscured)     |
| Enter    | Action button (login flow)    |
| First In | Action button (register flow) |

---

## Screen 3 — Home Page

| Property | Value                               |
| -------- | ----------------------------------- |
| Route    | `/home-page`                        |
| Class    | `HomePageScreen`                    |
| File     | `lib/screens/home_page_screen.dart` |

**Background:** Solid black hub layout (see the Overview diagram above for the
icon-block navigation into Screens 4–10).  
**Data source:** `playerSessionProvider` (Riverpod), not a route argument —
`AccountWithProfile` is only used transiently during the Screen 2 auth query.

> Note: this screen replaced the earlier `DashboardScreen` stub; the
> "AGENT PROFILE" field breakdown below now lives on Screen 4 — Profile.

---

## Screen 4 — Profile

| Property | Value                              |
| -------- | ---------------------------------- |
| Route    | `/profile`                         |
| Class    | `ProfileScreen`                    |
| File     | `lib/screens/profile_screen.dart`  |

### Sections & Fields

| Section       | Field          | Source                                        |
| ------------- | -------------- | --------------------------------------------- |
| AGENT PROFILE | ID             | `account.id`                                  |
|               | Handle         | `account.pseudo`                              |
|               | Rank           | `level.name` + level id (e.g. "Mouse · Lv.1") |
|               | Experience     | `profile.experience`                          |
| CAPABILITIES  | Software Power | `profile.softwarePower`                       |
|               | Hardware Power | `profile.hardwarePower`                       |
| REPUTATION    | Rating         | `profile.rating`                              |
|               | Karma          | `profile.karma` (1–100)                       |
|               | Wanted         | `profile.wanted` (1–100)                      |
|               | Popularity     | `profile.popularity`                          |
|               | Black Trust    | `profile.blackTrust` (1–100)                  |
| LEGEND        | Legend text    | `profile.legend` (full paragraph, italic)     |

---

## Data Models

| Model                | File                                   | Used by          |
| -------------------- | -------------------------------------- | ---------------- |
| `Account`            | `lib/models/account.dart`              | DB, Auth         |
| `Profile`            | `lib/models/profile.dart`              | DB, Dashboard    |
| `Level`              | `lib/models/level.dart`                | DB, Dashboard    |
| `AccountWithProfile` | `lib/models/account_with_profile.dart` | Auth query result (Screen 2) |

## Services

| Service           | File                                 | Responsibility                |
| ----------------- | ------------------------------------ | ----------------------------- |
| `DatabaseHelper`  | `lib/db/database_helper.dart`        | SQLite singleton, all queries |
| `AudioService`    | `lib/services/audio_service.dart`    | BGM start/stop/volume         |
| `SettingsService` | `lib/services/settings_service.dart` | shared_preferences load/save  |

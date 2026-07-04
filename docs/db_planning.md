# Database Schema Planning

## User Domain

### Relationship map
```
Account ─── ShowedTutorials [Post-Alpha]
│
Profile ─── Levels
│
├── UserSoftware ── [Sockets / Modifiers Post-Alpha]
│
├── UserHardware ── [Sockets / Modifiers Post-Alpha]
│
├── UserSkills [Post-Alpha]
│
└── Achievements [Post-Alpha]
```

### Tables

**accounts**

| Field         | Type    | Restriction | Description |
| ------------- | ------- | ----------- | ----------- |
| id            | int     | pk          | Internal DB PK |
| pseudo        | str     | unique, length 4-32 | User login name |
| pass          | str     | length 6-24 | SHA-256 hashed password |
| salt          | str     | not null    | Cryptographic salt |
| profile_id    | FK(profiles) | not null, cascade | Link to user profile |

**profiles**

| Field          | Type    | Restriction | Description |
| -------------- | ------- | ----------- | ----------- |
| id             | int     | pk          | Internal DB PK |
| profile_id     | str     | unique, not null | Display user ID (uppercase len=7, e.g. "09RTW44") |
| level_id       | FK(levels) | not null, default 1 | Link to current level rank |
| software_power | int     | not null, default 0 | Calculated total software power |
| hardware_power | int     | not null, default 0 | Calculated total hardware power |
| rating         | int     | not null, ge 0 | Special offer frequency/quality controller |
| karma          | int     | not null, 1-100 | Alignment parameter (unused in alpha) |
| wanted         | int     | not null, 0-100 | Trace/alert status from failed runs |
| popularity     | int     | not null, default 0 | Popularity parameter (unused in alpha) |
| black_trust    | int     | not null, 0-100 | Black market reputation |
| legend         | str     | not null, default '' | Randomly generated background story |
| experience     | int     | not null, ge 0 | Experience points count |
| epts_balance   | int     | not null, ge 0 | Main currency (earned via successful attacks) |
| uep_balance    | int     | not null, ge 0 | Premium currency (convertible to epts) |

**levels**

| Field       | Type    | Restriction | Description |
| ----------- | ------- | ----------- | ----------- |
| id          | int     | pk          | Rank level |
| name        | str     | unique, not null | Animal rank name (e.g. "Mouse", "Wolf") |
| description | str     | not null    | Description of the rank |

**user_software**

| Field               | Type    | Restriction | Description |
| ------------------- | ------- | ----------- | ----------- |
| id                  | int     | pk          | Internal DB PK |
| profile_id          | FK(profiles) | not null, cascade | Owner profile link |
| item_id             | FK(software_items) | not null | Link to software catalog item |
| current_level       | int     | not null, ge 1 | Current level of the software item |
| attack              | int     | not null, ge 1 | Attack power of the software core |
| penetration_ability | int     | not null, ge 1 | Defensive mitigation factor |
| residual_trace      | int     | not null, ge 0 | Detection risk multiplier |
| modificator_sockets | int     | not null, ge 1 | Slots for modification upgrades |
| *Constraints*       |         | UNIQUE(profile_id, item_id) | Prevent duplicate items per user |

**user_hardware**

| Field               | Type    | Restriction | Description |
| ------------------- | ------- | ----------- | ----------- |
| id                  | int     | pk          | Internal DB PK |
| profile_id          | FK(profiles) | not null, cascade | Owner profile link |
| item_id             | FK(hardware_items) | not null | Link to hardware catalog item |
| current_level       | int     | not null, ge 1 | Current upgrade level |
| compute_power       | int     | not null, ge 1 | Contributes to total hardware power |
| power_draw          | int     | not null, ge 0 | Resource usage cost |
| modificator_sockets | int     | not null, ge 1 | Modifiers slots count |
| *Constraints*       |         | UNIQUE(profile_id, item_id) | Prevent duplicate items per user |

---

## Store Domain

**software_items** (Store Catalog)

| Field             | Type    | Restriction | Description |
| ----------------- | ------- | ----------- | ----------- |
| id                | int     | pk          | Catalog item PK |
| name              | str     | unique, not null | Display name (e.g. "Hydra Brute") |
| soft_type_id      | FK(software_types) | not null | Type categorizer |
| description       | str     | not null    | Description for shop card |
| base_price        | int     | not null, ge 0 | Cost in shop |
| currency_type     | str     | "EPTS" / "UEP" | Used currency |
| req_level         | int     | FK(levels)  | Min rank level required to buy |
| req_black_trust   | int     | 0-100       | Min black trust required to buy |
| init_max_level    | int     | not null, default 5 | Standard max upgrade level |
| base_attack       | int     | not null, ge 1 | Starting attack parameter |
| base_penetration  | int     | not null, ge 1 | Starting penetration parameter |
| base_trace        | int     | not null, ge 0 | Starting trace parameter |
| sockets           | int     | not null, ge 1 | Starting socket slots |
| level_up_strategy | str/JSON| json_valid  | Stats modification mapping on level up |

**hardware_items** (Market Catalog)

| Field              | Type    | Restriction | Description |
| ------------------ | ------- | ----------- | ----------- |
| id                 | int     | pk          | Catalog item PK |
| name               | str     | unique, not null | Display name (e.g. "Overclocked NET Card") |
| hw_type            | str     | "CPU"/"RAM"/"NET"/"GPU"/"IO" | Category categorizer |
| description        | str     | not null    | Description for market card |
| base_price         | int     | not null, ge 0 | Cost on market |
| currency_type      | str     | "EPTS" / "UEP" | Used currency |
| req_level          | int     | FK(levels)  | Min rank level required to buy |
| req_black_trust    | int     | 0-100       | Min black trust required to buy |
| init_compute_power | int     | not null, ge 1 | Starting compute power |
| init_power_draw    | int     | not null, ge 0 | Starting power draw |
| sockets            | int     | not null, ge 1 | Starting socket slots |

**software_types**

| Field | Type | Restriction | Description |
| ----- | ---- | ----------- | ----------- |
| id    | int  | pk          | Hacking type PK |
| name  | str  | unique, not null | Phishing, Bruteforce, DDoS, Exploit |

**target_types**

| Field            | Type  | Restriction | Description |
| ---------------- | ----- | ----------- | ----------- |
| id               | int   | pk          | Type PK |
| name             | str   | unique, not null | Celebrities, Cyberpol, Corporations, etc. |
| base_trace_speed | int   | not null, ge 1 | Hacking detection tracing speed |
| risk_multiplier  | float | not null, ge 0 | Penalty multiplier on failure |

**target_templates**

| Field            | Type  | Restriction | Description |
| ---------------- | ----- | ----------- | ----------- |
| id               | int   | pk          | Template PK |
| type_id          | FK(target_types) | not null | Category categorizer |
| name             | str   | unique, not null | Display name |
| required_level   | int   | FK(levels)  | Min level to attempt hack |
| base_defense     | int   | not null, ge 1 | HP/Defense complexity of target |
| epts_reward      | int   | not null, ge 0 | Base crypto bounty |
| trust_reward     | int   | not null, ge 0 | Base black trust bounty |
| custom_mechanics | str/JSON | json_valid | Special mechanics configs |

**mission_types**

| Field                | Type  | Restriction | Description |
| -------------------- | ----- | ----------- | ----------- |
| id                   | int   | pk          | Mission type PK |
| name                 | str   | unique, not null | e.g. "Data Theft", "DDoS Sabotage" |
| description          | str   | not null    | Task objective |
| primary_soft_type_id | FK(software_types) | not null | Soft type matching this mission |
| base_reward_mult     | float | not null, ge 0 | Base multiplier for rewards |

**effectiveness_matrix**

| Field          | Type  | Restriction | Description |
| -------------- | ----- | ----------- | ----------- |
| soft_type_id   | FK(software_types) | pk | Soft Type Category |
| target_type_id | FK(target_types)   | pk | Target Type Category |
| damage_mult    | float | not null, ge 0 | Effectiveness damage mult |
| trace_mult     | float | not null, ge 0 | Detection trace mult |

---

## Log & History Domain

**attack_log**

| Field              | Type  | Restriction | Description |
| ------------------ | ----- | ----------- | ----------- |
| id                 | int   | pk          | Log entry PK |
| profile_id         | FK(profiles) | not null, cascade | Owner profile link |
| target_template_id | FK(target_templates) | not null | Hacked target |
| mission_type_id    | FK(mission_types) | not null | Selected mission |
| result             | str   | 'success'/'hard'/'fail' | Hack output result |
| epts_delta         | int   | not null    | Balance delta |
| wanted_delta       | int   | not null    | Wanted delta |
| trust_delta        | int   | not null    | Trust delta |
| created_at         | str   | not null, default datetime('now') | Event timestamp |

---

## Post-Alpha Features

*AvailableSoftImprovements / AvailableHardImprovements, SoftUpgrades / HardUpgrades, UserSkills, Achievements / UserAchievements, ShowedTutorials* are postponed for post-alpha stages of the project to reduce complexity in the MVP.

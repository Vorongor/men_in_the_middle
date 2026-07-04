# Крок 03 — Повна схема БД (v3)

**Статус: ✅ виконано 2026-07-04** (див. Summary внизу) · Залежить від: 02

## Мета

Розширити SQLite-схему з 3 таблиць до повного ігрового домену за [db_planning.md](../db_planning.md), узгодивши розбіжності між документом і кодом. Після цього кроку схема **заморожується**, зміни — тільки міграціями.

## Розбіжності документ ↔ код, які треба закрити ДО написання SQL

| Питання | db_planning.md | Код зараз | Рішення для v3 |
| --- | --- | --- | --- |
| Валюти | `epts_balance`, `uep_balance` | відсутні | Додати `epts_balance` (uep — після альфи, але колонку закласти) |
| Поля профілю | rating, wanted, black_trust, exp | + karma, popularity | Лишити karma/popularity як резерв або видалити — **вирішити й зафіксувати** |
| `profile_id` (display, "09RTW44") | є | немає | Додати, генерувати при реєстрації |
| JSONB | вказано JSONB | — | SQLite: колонка TEXT + `json_valid()` CHECK; парсинг у Dart-моделях |
| `UserSoftware.name unique` | unique глобально | — | Unique на пару (user_id, name), не глобально |
| Wanted діапазон | 0–100 | CHECK 1–100 | 0–100 (0 = чистий) |

## Схема v3 (порядок створення)

**Каталоги (статичний контент, сідиться з JSON у кроці 04):**

- [x] `software_types` (id, name) — Phishing, Bruteforce, DDoS, Exploit
- [x] `target_types` (id, name, base_trace_speed, risk_multiplier)
- [x] `mission_types` (id, name, description, primary_soft_type_id, base_reward_mult)
- [x] `software_items` (каталог Store): name, soft_type_id, description, base_price, req_level, req_black_trust, init_max_level, base_attack, base_penetration, base_trace, sockets, level_up_strategy TEXT(json)
- [x] `hardware_items` (каталог Market): name, hw_type (CHECK in CPU/RAM/NET/GPU/IO), description, base_price, req_level, req_black_trust, init_compute_power, init_power_draw, sockets
- [x] `target_templates`: type_id, name, required_level, base_defense, epts_reward, trust_reward, custom_mechanics TEXT(json)
- [x] `effectiveness_matrix` (soft_type_id, target_type_id, damage_mult, trace_mult) — матриця «камінь-ножиці-папір» як дані, не код

**Інвентар гравця:**

- [x] `user_software`: profile_id, item_id → software_items, current_level, attack, penetration_ability, residual_trace, modificator_sockets
- [x] `user_hardware`: profile_id, item_id → hardware_items, current_level, compute_power, power_draw, modificator_sockets

**Історія (потрібна для результатів і новин):**

- [x] `attack_log`: profile_id, target_template_id, mission_type_id, result (success/hard/fail), epts_delta, wanted_delta, trust_delta, created_at

**Відкладено після альфи:** soft/hard upgrades (сокети-модифікатори), user_skills, user_achievements, showed_tutorials. У v3 їх НЕ створюємо — менше мертвих таблиць.

## Задачі

- [x] Оновити `profiles`: + epts_balance, + display profile_id, wanted CHECK 0–100
- [x] SQL усіх таблиць вище + індекси (profile_id у інвентарних, unique-пари)
- [x] `PRAGMA foreign_keys = ON` при відкритті БД
- [x] Версія БД → 4; на дев-етапі wipe-міграція допустима, але після цього кроку — тільки ALTER-міграції
- [x] Dart-моделі: `SoftwareItem`, `HardwareItem`, `UserSoftware`, `UserHardware`, `TargetTemplate`, `TargetType`, `MissionType`, `AttackLogEntry` (fromMap/toMap, парсинг json-полів)
- [x] Розширити `Profile` модель новими полями
- [x] Unit-тести: створення схеми на in-memory БД, CRUD кожного репозиторію, CHECK-обмеження спрацьовують

## Виправлення в db_planning.md (супутнє)

- [x] Перейменувати файл → `db_planning.md`, виправити typos (`level_up_strategu`, `UserHardwarare`, `deacription`)
- [x] Дописати відсутні таблиці `AvailiableSoftImprovements` / `AvailiableHardImprovements` або позначити «post-alpha»
- [x] Синхронізувати документ із фактичною v3

## Критерії приймання

- [x] Схема v3 створюється з нуля і через міграцію 3→4
- [x] Всі моделі мають fromMap/toMap round-trip тести
- [x] db_planning.md відповідає реальній схемі

---

## Summary (виконано 2026-07-04)

### Схема бази даних (v4)

Схема бази даних розширена з 3 таблиць до повноцінного ігрового домену. Всі ігрові об'єкти (цілі, типи атак, програмне та апаратне забезпечення) тепер підтримуються реляційно на рівні SQLite.

Створені таблиці:
1. **Каталоги (статичний контент):**
   - `software_types` (Phishing, Bruteforce, DDoS, Exploit)
   - `target_types` (Celebs, Corp, Gov, Cyberpol, etc.)
   - `mission_types` (DDoS Sabotage, Data Theft, etc.)
   - `software_items` (експлойти та скрипти в Store)
   - `hardware_items` (процесори, мережеві карти в Market)
   - `target_templates` (шаблони цілей для Target Board)
   - `effectiveness_matrix` (множники шкоди та трейсу для типу софту проти типу ворога - "камінь-ножиці-папір")

2. **Динамічний інвентар гравця:**
   - `user_software` (придбаний софт з параметрами attack, penetration_ability, residual_trace)
   - `user_hardware` (придбане залізо з compute_power та power_draw)
   - `attack_log` (історія успішних та невдалих атак з дельтами валют, хотів та репутації)

3. **Індекси та обмеження:**
   - Обмеження `CHECK(wanted BETWEEN 0 AND 100)` та `CHECK(black_trust BETWEEN 0 AND 100)`.
   - Обмеження `UNIQUE(profile_id, item_id)` для інвентарю користувача (унеможливлює дублювання).
   - Індекси на `profile_id` у таблицях інвентарю та логів атак для прискорення вибірки.

### Зміни в профілі та акаунтах

- Додано текстове поле `profile_id` (display ID, наприклад "09RTW44") до `profiles`. Воно генерується автоматично при реєстрації (`lib/utils/profile_id_generator.dart`).
- Додано поля балансу `epts_balance` та `uep_balance`.
- Версія бази даних оновлена з 3 до 4. Метод `_migrate` повністю очищує старі таблиці перед оновленням схеми.

### Dart-моделі

Створені нові моделі з підтримкою `fromMap` та `toMap`:
- `SoftwareItem` (автоматичний `jsonDecode`/`jsonEncode` для `level_up_strategy`)
- `HardwareItem`
- `UserSoftware`
- `UserHardware`
- `TargetType`
- `TargetTemplate` (автоматичний `jsonDecode`/`jsonEncode` для `custom_mechanics`)
- `MissionType`
- `AttackLogEntry`

Профіль (`Profile`) було оновлено для підтримки нових полів `profileId`, `eptsBalance`, `uepBalance`. Мапінг у `DatabaseHelper` синхронізовано.

### Тести та аналізи

- Написано 11 нових тестів в [test/database_schema_test.dart](file:///c:/Development/men_in_the_middle/test/database_schema_test.dart) (8 round-trip тестів для кожної моделі, 3 тести на створення таблиць та роботу SQL constraints, включаючи `json_valid` та обмеження `wanted`).
- Всі 21 тести проекту проходять успішно (`flutter test`).
- Статичний аналіз чистого коду (`flutter analyze` — 0 warnings/issues).

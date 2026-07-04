# Крок 01 — Initial Setup (каркас проєкту)

**Статус: ✅ виконано 2026-07-04** (див. Summary внизу)

## Мета

Робочий каркас застосунку: запуск на Windows/Android, навігація по всіх екранах, авторизація, налаштування, аудіо.

## Зроблено

- [x] Flutter-проєкт, pubspec із залежностями (flame, flame_audio, sqflite + ffi, media_kit, google_fonts, crypto, shared_preferences)
- [x] `App` + іменовані роути для всіх 18 екранів (`lib/utils/routes.dart`)
- [x] Screen 1 — Main Menu з відео-фоном (`media_kit`) і фолбеком-картинкою
- [x] Screen 1.2 — Settings: mute/general/music/effects, збереження у shared_preferences
- [x] Screen 2 — Auth: реєстрація/вхід, SHA-256 хеш пароля, випадкова «легенда» з `assets/data/legends.json`
- [x] `DatabaseHelper`: SQLite (sqflite_common_ffi на десктопі), таблиці accounts/profiles/levels, seed 10 рівнів (Mouse → Wolf)
- [x] `AudioService` (BGM), `SettingsService`
- [x] `GameScaffold` — спільний каркас ігрових екранів
- [x] Wireframe-заглушки екранів 3–10 (навігація працює наскрізно)

## Залишок у межах кроку

- [x] **CI-мінімум:** GitHub Actions — `flutter analyze` + `flutter test` на push (1 workflow-файл)
- [x] **Лінт-чистота:** `flutter analyze` без warnings; увімкнути додаткові правила у `analysis_options.yaml`
- [x] **Smoke-тест:** один widget-тест «застосунок стартує, показує Main Menu»
- [x] **Виправити збіг alias-ключів у SQL**: у `login()` `l.id AS level_id` перезаписував `p.level_id` — зараз працює випадково, бо значення збігаються
- [x] Задокументувати запуск проєкту в README (flutter run -d windows, вимоги)

## Критерії приймання

- `flutter analyze` — 0 issues; `flutter test` — зелений
- Застосунок стартує на Windows і Android, реєстрація → Home Page працює
- CI зелений на main

---

## Summary (виконано 2026-07-04)

Крок закрито разом із рефакторингом за [docs/review.md](../review.md) — проведено підготовку кодової бази до кроків 02–03.

### Рефакторинг за рев'ю

**1. Виправлено alias-баг у SQL (`DatabaseHelper.login`).** Дубльований alias `level_id` (`p.level_id` і `l.id`) мовчки перезаписувався в результаті join-запиту. Два майже ідентичні SELECT-и (login/register) об'єднано в одну спільну проєкцію `_joinedSelect` — запити більше не можуть розійтися.

**2. Солене хешування паролів.** Раніше: несолений SHA-256, хеш рахувався в UI-шарі (`login_screen.dart`). Тепер:
- новий [lib/utils/password_hasher.dart](../../lib/utils/password_hasher.dart): `Random.secure()` сіль (16 байт, base64url) + SHA-256;
- хешування перенесено всередину `DatabaseHelper` — UI передає raw-пароль, крипто-логіка в одному місці;
- колонка `accounts.salt`, версія БД 2 → 3 (dev-wipe міграція, локальні акаунти перестворяться);
- реєстрація (profile + account INSERT) обгорнута в транзакцію;
- `PRAGMA foreign_keys = ON` при відкритті БД (з плану кроку 03, зроблено достроково).

**3. Видалено мертвий код** (рекомендація рев'ю §2): `lib/screens/dashboard_screen.dart` (замінений HomePageScreen), `lib/screens/game_screen.dart` і `lib/game/middlemen_game.dart` (порожній FlameGame-стаб «гра всього застосунку» — хибний напрям; міні-ігри будуть окремими FlameGame на кроці 08), legacy-alias `Routes.dashboard`.

**4. `VideoBg` став стійким до відсутності media_kit**: створення `Player` у try/catch, при збої — фолбек на статичну картинку. Це і продакшн-фікс (девайси без нативних біб.), і те, що розблокувало widget-тести.

### Залишки кроку 01

- **Лінти посилено** ([analysis_options.yaml](../../analysis_options.yaml)): strict-casts/inference/raw-types + 9 додаткових правил (unawaited_futures, avoid_dynamic_calls, prefer_single_quotes…). Виправлено всі 16 знахідок: сортування імпортів, tearoff у home_screen, непід'awaited-ені Future у login_screen/audio_service, dynamic-виклики у legend_loader, нетипізований `controls` у video_bg.
- **CI**: [.github/workflows/ci.yml](../../.github/workflows/ci.yml) — `flutter analyze` + `flutter test` на push у main і PR (ubuntu, stable, з кешем).
- **Тести**: наявний смоук-тест Main Menu тепер проходить; додано [test/password_hasher_test.dart](../../test/password_hasher_test.dart) (4 тести: verify ok/fail, унікальність солі, ентропія).
- **README** переписано: опис гри, лінки на документацію, вимоги, запуск, перевірки, структура lib/.

### Верифікація

- `flutter analyze` — **0 issues**
- `flutter test` — **5/5 passed**
- `flutter build windows --debug` — збірка проходить

**Супутній фікс тулчейна:** після оновлення Visual Studio до 2026 (MSVC 14.51) Windows-збірка ламалась двічі: (1) застарілий CMake-кеш від VS 2019 — вилікувано видаленням `build/windows`; (2) hard error STL1011 у плагіні `audioplayers_windows` (використовує deprecated `<experimental/coroutine>`) — додано define `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` у [windows/CMakeLists.txt](../../windows/CMakeLists.txt); прибрати, коли audioplayers мігрує на C++20 `<coroutine>`.

### Що свідомо НЕ робилося тут (наступні кроки)

- Riverpod/сесія гравця, репозиторії — крок 02
- Рішення sqflite → Drift, схема v3 — крок 03
- Валідація полів pseudo/pass (4–32 / 6–24 з db-плану) — разом з кроком 02 (форма логіну)

# The MiddleMen

«Хижаки цифрових джунглів» — одиночна офлайн-гра про хакера-найманця: контракти, підготовка атак, аркадні міні-ігри, прокачка софту й заліза. Flutter + Flame.

## Документація

| Документ | Зміст |
| --- | --- |
| [docs/game_concept.md](docs/game_concept.md) | Ігровий концепт, core loop, механіки, міні-ігри |
| [docs/screen_map.md](docs/screen_map.md) | Карта екранів і навігація |
| [docs/db_planning.md](docs/db_planning.md) | План схеми БД |
| [docs/review.md](docs/review.md) | Технічне рев'ю стеку та архітектури |
| [docs/planning/general_apha.md](docs/planning/general_apha.md) | План розробки 0 → альфа + покрокові плани step_01…step_10 |

## Вимоги

- Flutter SDK ≥ 3.12 (канал stable)
- Windows: Visual Studio 2022 з «Desktop development with C++» (для десктоп-збірки)
- Android: Android Studio / SDK 34+

## Запуск

```bash
flutter pub get
flutter run -d windows   # десктоп (основна dev-платформа)
flutter run -d <device>  # Android
```

БД (SQLite, файл `middlemen.db`) створюється автоматично при першому запуску. На дев-етапі зміна версії схеми стирає локальні дані.

## Перевірки

```bash
flutter analyze
flutter test
```

Обидві команди виконуються в CI (GitHub Actions) на кожен push у main і на PR.

## Структура

```
lib/
  app.dart, main.dart      — точка входу, роути
  screens/                 — екрани (Screen 1–10 за screen_map.md)
  widgets/                 — спільні віджети (GameScaffold, VideoBg)
  db/                      — SQLite (DatabaseHelper)
  models/                  — моделі даних
  services/                — аудіо, налаштування
  utils/                   — константи, роути, хешування паролів
assets/
  data/                    — ігровий контент (JSON)
  media/, images/, audio/  — медіа-асети
```

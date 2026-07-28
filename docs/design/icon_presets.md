# Іконки: реєстр, пайплайн і правила

> Крок 06 Alpha 2.0. Сира мапа асетів власника — [icons_map.md](../planning/icons_map.md).
> Палітра і кеглі — [design_tokens.md](design_tokens.md).

Документ описує **дві незалежні системи**:

1. **Chrome-асети** — відомі PNG, підключені напряму через `AppImages` (кнопки, хаб, фони).
2. **Каталожні іконки** — резолвляться з даних через `icon_key`, без правок Dart-коду.

---

## 1. Chrome-асети (`AppImages`)

Єдине джерело шляхів — `lib/utils/constants.dart`. **Жодного літерала `assets/images/...` поза цим класом.**

| Константа                | Файл                                    | Де в UI                            | Стан |
| ------------------------ | --------------------------------------- | ---------------------------------- | ---- |
| `AppImages.backArrow`    | `Back_arrow.png`                        | `GameScaffold` → leading           | ✅   |
| `AppImages.settings`     | `Setting.png`                           | `GameScaffold` → actions           | ✅   |
| `AppImages.navStore`     | `Darknet.png`                           | Хаб, плитка Store                  | ✅   |
| `AppImages.navMarket`    | `Spider_store.png`                      | Хаб, плитка Market                 | ✅   |
| `AppImages.navWorkshop`  | `Workshop.png`                          | Хаб, плитка Workshop               | ✅   |
| `AppImages.navNews`      | `News.png`                              | Хаб, плитка News                   | ✅   |
| `AppImages.targetBoardBg`| `Targets_list.png`                      | Фон блоку дошки на хабі            | ⬜ потребує макета |
| `AppImages.targetItemBg` | `Target.png`                            | Фон елемента дошки                 | ⬜ потребує макета |
| `AppImages.hackerGreen`  | `hacker/hacker_green.png`               | Screen 1 (меню)                    | ⬜ потребує макета |
| `AppImages.hackerAnon`   | `hacker/hacker_green_anonimoys.png`     | Screen 2 (auth)                    | ⬜ потребує макета |
| `AppImages.info`         | `icons/Info.png`                        | ще не призначено                   | ⬜   |
| —                        | **Profile — асета немає**               | Хаб, плитка Profile                | 🔴 прогалина |

Рендериться віджетом `AppImageIcon(asset, size:, color:)`. `color` **не передавати** для
кольорового арту — тінт сплющує PNG в один тон.

## 2. Каталожні іконки: пайплайн `icon_key`

### Ланцюжок резолву

```
icon_key предмета  →  assets/images/ui/icons/<icon_key>.png
       ↓ файлу немає або ключ порожній
дефолтний гліф свого типу (AppIconKind.fallbackGlyph)
```

Резолв відбувається у `Image.errorBuilder`, тому **биті ключі не валять UI** — вони
деградують до гліфа. Саме тому існує тест (нижче), інакше прогалина лишиться непоміченою.

### Як додати іконку новому предмету

1. Покласти PNG у `assets/images/ui/icons/` — ім'я файлу і є ключ (`ddos_cannon.png` → `ddos_cannon`).
2. Дописати `"icon_key": "ddos_cannon"` у відповідний JSON каталогу.
3. Все. Dart-код не змінюється.

Поле `icon_key` — **опційне** у всіх чотирьох каталогах:
`software_items.json`, `hardware_items.json`, `target_types.json`, `mission_types.json`.

### Типи і дефолтні гліфи

| `AppIconKind` | Каталог           | Fallback-гліф              |
| ------------- | ----------------- | -------------------------- |
| `software`    | `software_items`  | `Icons.terminal`           |
| `hardware`    | `hardware_items`  | `Icons.memory_outlined`    |
| `target`      | `target_types`    | `Icons.gps_fixed`          |
| `mission`     | `mission_types`   | `Icons.assignment_outlined`|
| `generic`     | —                 | `Icons.help_outline`       |

### Схема БД

`icon_key TEXT` (nullable) у чотирьох каталожних таблицях.
`_dbVersion = 7`, `ContentSeeder.currentContentVersion = 3`.

> ⚠️ `DatabaseHelper._migrate()` — це drop-and-recreate **усіх** таблиць, включно з
> `accounts`/`profiles`. Підняття `_dbVersion` до 7 **стирає збереження гравця**.
> Для альфи прийнятно; до бети потрібна інкрементальна міграція.

### Тест-гарантія

`test/content_pipeline_test.dart` → група `icon_key pipeline (step 06)`:

- кожен непорожній `icon_key` у 4 каталогах має відповідний PNG — інакше CI червоний;
- колонка `icon_key` присутня у 4 таблицях, значення переживає round-trip JSON → БД.

## 3. Донабір v1 — що ще треба намалювати

Стиль-еталон: `Darknet.png`, `Workshop.png`, `News.png`. Палітра — Варіант 1
«Classic Terminal». Формат PNG. Змішувати стилі заборонено.

| Набір          | К-сть | Ключі                                                        |
| -------------- | ----- | ------------------------------------------------------------ |
| Типи софту     | 4     | `phishing`, `bruteforce`, `ddos`, `exploit`                   |
| Типи заліза    | 5     | `cpu`, `ram`, `net`, `gpu`, `io`                              |
| Типи цілей     | 7     | за `target_types.json`                                        |
| Типи місій     | 5     | за `mission_types.json`                                       |
| Хаб            | 1     | іконка Profile                                                |

**Разом: 22 файли.** Автор — власний дизайнер проєкту (як і решта графіки), тож
питання ліцензування не виникає; див. `CREDITS.md`.

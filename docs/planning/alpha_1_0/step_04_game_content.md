# Крок 04 — Контент-пайплайн (ігрові дані)

**Статус: ⬜ не розпочато** · Залежить від: 03 · Можна паралелити з 05

## Мета

Весь ігровий контент — предмети, цілі, матриця ефективності, крива рівнів — живе у JSON-асетах і сідиться в БД при першому запуску / оновленні версії контенту. Баланс правиться редагуванням JSON без зміни коду.

## Структура асетів

```
assets/data/
  legends.json            (вже є)
  catalog/
    software_items.json    ~12 предметів: по 3 на кожен із 4 типів (tier 1–3)
    hardware_items.json    ~10 предметів: CPU/RAM/NET по 3 tier-и + 1 GPU
    target_types.json      7 типів з base_trace_speed, risk_multiplier
    target_templates.json  ~15 шаблонів цілей, розкиданих по required_level 1–6
    mission_types.json     4 типи місій (Data Theft, Bruteforce, Sabotage, Exploit)
    effectiveness.json     матриця 4 soft_types × 7 target_types (damage_mult, trace_mult)
    level_curve.json       пороги exp для рівнів 1–10 + розблокування
```

## Задачі

### 4.1 Формат і валідація

- [ ] Задокументувати JSON-схему кожного файлу (короткий `catalog/README.md`)
- [ ] `ContentValidator` (Dart): перевірка референсів (soft_type існує, ціни ≥ 0, матриця повна) — виконується в unit-тесті, зламаний контент валить CI

### 4.2 Seeder

- [ ] `ContentSeeder` (`lib/db/content_seeder.dart`): читає JSON → upsert у каталожні таблиці
- [ ] Таблиця `meta(key, value)` з `content_version`; seeder перезаливає каталоги при підвищенні версії, не чіпаючи інвентар гравців
- [ ] Виклик після відкриття БД у `DatabaseHelper`

### 4.3 Початковий контент (перший баланс-прохід)

- [ ] Софт tier-1 кожного типу доступний з рівня 1, ціни 100–300 epts
- [ ] Стартовий інвентар нового гравця: 1 безкоштовний Phishing Mailer tier-1 + базовий CPU (додати в `register()`)
- [ ] Стартовий баланс: 150 epts
- [ ] Матриця ефективності за концептом: сильна відповідність ×2.0, нейтральна ×1.0, слабка ×0.2 (+ trace_mult 0.8/1.0/1.5)
- [ ] Крива рівнів: рівень N потребує ~`100 * N^1.6` exp (уточнюється на кроці 10)

### 4.4 CatalogRepository

- [ ] Методи: `storeItems(profile)` (фільтр за req_level/req_black_trust), `marketItems(profile)`, `targetTemplatesFor(level)`, `effectiveness(softType, targetType)`

## Критерії приймання

- Чиста інсталяція: БД наповнена каталогами, новий акаунт має стартовий інвентар і 150 epts
- Зміна числа у JSON + bump content_version → нові значення в грі без реінсталяції
- ContentValidator у CI ловить битий референс (тест із навмисно зіпсованим фікстур-файлом)

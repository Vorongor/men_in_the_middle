# Крок 08 — Міні-гра «Перехоплення потоку» (Data Sniffer, Flame)

**Статус: ✅ виконано 2026-07-04** · Залежить від: 07 · див. Summary внизу

## Мета

Перша справжня міні-гра на Flame, вбудована у флоу атаки замість заглушки. Обрано «Перехоплення потоку» — найпростіша механіка (рух + падаючі об'єкти), покриває Phishing-місії, якими грає новачок.

## Геймплей (з концепту)

- Згори падають пакети: зелені (ловити), червоні (уникати); знизу — сніфер, рух вліво/вправо (drag / клавіші на десктопі)
- Мета: зловити N зелених до закінчення таймера; торкання червоного — штраф до таймера
- Вплив статів: `attack` → ширина сніфера і ліміт прощених червоних; `penetration_ability` → повільніше падіння і менша частка червоних; `time_budget` з Resolution Engine → стартовий таймер

## Задачі

### 8.1 Ядро гри (`lib/game/sniffer/`)

- [x] `SnifferGame extends FlameGame` з `GameWidget`, вбудований у Screen 7.2 (без окремого інтерфейсу `Minigame` — див. «Відхилення від плану»)
- [x] Компоненти: `SnifferPaddle` (drag + keyboard), `Packet` (spawn зверху, самовидалення поза екраном), `PacketSpawner` (частота/співвідношення з difficulty), HUD (таймер, прогрес X/N, влучені червоні)
- [x] Колізії: paddle ↔ packet (Flame collision detection, `RectangleHitbox`)
- [x] Конфіг складності `SnifferConfig` обчислюється з `AttackSetup` (чиста функція — unit-тестується)
- [x] Завершення → `MinigameOutcome(success, timeRatio)` → існуючий resolution-флоу (без окремого поля `perfect` — див. «Відхилення від плану»)

### 8.2 Ускладнення (scaling per difficulty)

- [x] Швидкість падіння росте з defense цілі
- [x] «Пакет-хамелеон» (червоний маскується під зелений, розкривається за 0.5с) — з defense ≥ 150 (поріг MEDIUM)
- [x] Прибрати debug-кнопки WIN/LOSE зі Screen 7.2 (лишити за `kDebugMode`)

### 8.3 Ігрове відчуття

- [x] SFX-хук: `AudioService.playSfx()` (catch / hit / win / lose), поважає `effectiveEffectsVolume`; **клипів ще немає** — див. «Відома проблема»
- [x] Простий VFX: спалах при ловінні (`_CatchFlash`, canvas-компонент), тряска при червоному (Flutter-рівень, `Transform.translate`)
- [x] Пауза при згортанні застосунку (`WidgetsBindingObserver` → `pauseEngine`/`resumeEngine`); кнопка Abort = провал з підтвердженням (`AlertDialog`)

### 8.4 Debug-роут

- [x] `/debug/sniffer` (лише `kDebugMode`): повзунки для всіх полів `SnifferConfig`, запуск міні-гри в ізоляції без профілю/контракту/персистенції

### 8.5 Тести

- [x] Unit: `SnifferConfig` з різних `AttackSetup` (слабкий/сильний софт, легка/важка ціль, межі clamp) — 6 тестів, `test/sniffer_config_test.dart`
- [x] Unit: підрахунок outcome (X зловлено, штрафи, timeRatio, межові випадки) — 8 тестів, `test/sniffer_outcome_test.dart`
- [ ] Ручний тест-чекліст: 60 fps на цільовому Android-девайсі, керування пальцем зручне — **не виконано** (немає фізичного Android-пристрою в цьому середовищі; потрібен ручний прохід перед збіркою альфи)

## Критерії приймання

- [x] Атака Phishing-типу проходиться через справжню міні-гру end-to-end
- [x] Сильніший софт відчутно полегшує гру (ширший сніфер, повільніші пакети) — підтверджено тестами scaling
- [x] Інші 3 типи місій поки використовують заглушку (позначено в UI як «AUTO-RESOLVE») — це свідоме обмеження альфи

---

## Summary (виконано 2026-07-04)

### Реалізовано

**Чиста логіка** (`lib/game/sniffer/`, без Flame/Flutter-залежностей, unit-тестована без bindings):
- `sniffer_config.dart` — `SnifferConfig.fromSetup(AttackSetup)`: paddleWidthFactor і allowedRedHits ростуть з `attack`; fallSpeed і redRatio падають з `penetration_ability`; targetCatches, fallSpeed і spawnInterval ростуть зі складністю цілі (`contract.defense`); chameleonChance активується від defense ≥ 150. `timeBudgetSeconds` делегується в `ResolutionEngine.timeBudgetSeconds()`, щоб прев'ю на Attack Prep і реальний таймер міні-гри завжди збігались.
- `sniffer_outcome.dart` — `SnifferOutcomeCalculator.compute()`: success вимагає одночасно `caughtGreen >= targetCatches` і `redHits <= allowedRedHits`; на невдачі `timeRatio` завжди 0 (успіх без «часу, що лишився» не має сенсу).

**Flame-компоненти**:
- `packet.dart` — `Packet` (зелений/червоний, хамелеон розкривається через 0.5с зміною кольору й цифри-лейбла), самостійно видаляється, впавши за межі екрана; на колізії з паддлом викликає `game.registerCatch()`.
- `sniffer_paddle.dart` — `SnifferPaddle` з межами руху, що перераховуються на resize.
- `packet_spawner.dart` — спавнить пакети за `spawnIntervalSeconds`, зупиняється через `game.isSpawning`.
- `sniffer_game.dart` — `SnifferGame extends FlameGame with HasCollisionDetection, KeyboardEvents`: HUD (таймер/прогрес/хіти) у `camera.viewport` (не рухається при тряске), геймплей у `world`; клавіші ←/→ рухають паддл через накопичення `_keysDown` в `update()`; `abort()` завжди дає `fail`, `_finish()` рахує через `SnifferOutcomeCalculator`.

**Інтеграція в Attack (7.2)** (`attack_screen.dart` переписано): Phishing-місії (`missionPrimarySoftTypeId == 1`) отримують `_SnifferMinigame` (обгортка з `GestureDetector` для драгу і `WidgetsBindingObserver` для паузи на background); інші місії — `_AutoResolvePanel` з детермінованою формулою (`effectiveAttack / defense >= 0.5`); `_DebugOutcomeBar` (PERFECT/SLOW/FAIL) видима лише при `kDebugMode`; кнопка ABORT з `AlertDialog`-підтвердженням.

**Debug-інструмент**: `lib/screens/debug_sniffer_screen.dart`, роут `/debug/sniffer` зареєстрований умовно в `app.dart` (`if (kDebugMode) ...`) — повзунки для всіх 8 полів `SnifferConfig`, запуск гри в ізоляції, результат у діалозі.

### Відхилення від плану

- **Без окремого інтерфейсу `Minigame`.** План кроку 07/08 згадував абстракцію `Widget build(AttackSetup, onComplete(MinigameOutcome))`. Замість неї `AttackScreen` напряму перемикається між `_SnifferMinigame` і `_AutoResolvePanel` за типом місії — простіше, і решта флоу (сесія атаки, resolution) вже й так живе в `attackSessionProvider` з кроку 07, тож окрема абстракція над відображенням нічого не додавала.
- **`MinigameOutcome.perfect` лишився геттером, не полем** (рішення кроку 07, підтверджене тут): `perfect = success && timeRatio > 0.5` обчислюється з `timeRatio`, який `SnifferOutcomeCalculator` вже повертає коректно — зберігати його окремо означало б ризик розсинхронізації.
- **Тряска — на рівні Flutter, не Flame-камери.** У Flame 1.37 `FlameGame` за замовчуванням використовує `World`+`CameraComponent`, де світова точка (0,0) відображається в *центрі* вьюпорта (`viewfinder.anchor = Anchor.center` за замовчуванням). Щоб зберегти звичну систему координат «(0,0) = лівий верхній кут», `onLoad()` явно виставляє `camera.viewfinder.anchor = Anchor.topLeft`. Ефект тряски після цього можна було б зробити зсувом `viewfinder.position`, але це рухало б і HUD, якби він лежав у `world`; замість боротьби з камерою HUD винесено у `camera.viewport` (не рухається), а тряска — це `Transform.translate` навколо `GameWidget` у `_SnifferMinigame`, керований звичайним `AnimationController`. Простіше, без ризику зіткнутися з нюансами Camera API.
- **Драг — через `GestureDetector`, не `DragCallbacks`.** Flame має власний механізм drag-колбеків для компонентів, але він розрахований на компоненти всередині дерева, а не на гру-корінь; для «драг у будь-якому місці екрана рухає паддл» простіше й надійніше обгорнути `GameWidget` у Flutter-`GestureDetector` і форвардити `dx` в `game.dragPaddleBy()`.

### Відома проблема (не блокує крок)

**Немає реальних звукових файлів.** `assets/audio/` містить лише `main_theme.mp3`; SFX-константи (`sfxCatch`, `sfxHit`, `sfxWin`, `sfxLose`) вказують на файли, яких ще не існує. `AudioService.playSfx()` свідомо ковтає помилку (`try/catch` + `debugPrint`), тож гра не падає, але звуку поки не буде. Потрібен окремий аудіо-пас (крок 10 або раніше) з реальними кліпами.

**Ручного тесту на Android-девайсі не проведено** — середовище розробки не має підключеного фізичного пристрою; рекомендується провести перед збіркою альфи (крок 10).

### Верифікація

- `flutter analyze` — **0 issues** (194с на холодну — перша компіляція нових Flame-класів; повторні прогони швидші).
- `test/sniffer_config_test.dart` — **6/6** (делегування timeBudgetSeconds, скейлінг софту, скейлінг складності цілі, межі clamp на екстремальних вхідних).
- `test/sniffer_outcome_test.dart` — **8/8** (успіх/провал на межах targetCatches і allowedRedHits, кламп timeRatio, нульовий time-budget).
- Повний наявний набір (без двох pre-existing зависаючих widget-тестів з кроку 07, не займаних цим кроком) — **61/61 пройдено**, регресій немає.

### Що лишається наступним крокам

- Крок 09: `LevelService`, ефекти wanted — незалежно від міні-гри.
- Крок 10: реальні SFX-файли; ручний тест на Android (fps, зручність керування пальцем); можливо — розширити AUTO-RESOLVE-місії власними міні-іграми (за межами альфи, але якщо буде час).
- Досі не усунено: зависання `economy_widgets_test.dart` / `target_board_widgets_test.dart` (задокументовано в кроці 07, не зачіпалося тут).

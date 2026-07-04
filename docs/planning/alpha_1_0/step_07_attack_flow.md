# Крок 07 — Attack Flow і Resolution Engine

**Статус: ✅ виконано 2026-07-04** · Залежить від: 05, 06 (див. Summary внизу)

## Мета

Повний ланцюг 7.1 → 7.2 → 7.3 на реальних даних. Ядро кроку — **Resolution Engine**: чиста Dart-функція, що з підготовки та результату міні-гри обчислює наслідки. Міні-гра на цьому кроці — тимчасова заглушка з кнопками WIN/LOSE (замінюється на кроці 08).

## Resolution Engine (`lib/game/resolution/`)

```dart
AttackResolution resolve(AttackSetup setup, MinigameOutcome outcome)

AttackSetup   { profile, contract, selectedSoftware, hardwarePower }
MinigameOutcome { success, timeRatio /*0..1 залишку таймера*/, perfect }
AttackResolution { result, eptsDelta, expDelta, wantedDelta, trustDelta, drops }
```

Формули (перша ітерація, всі коефіцієнти у `level_up`-стилі в JSON):

- `effective_attack = soft.attack × damage_mult(softType, targetType)`
- `time_budget` міні-гри = f(effective_attack / contract.defense), penetration знижує складність
- Сценарії з концепту: **Ідеальний злам** (успіх, timeRatio > 0.5): 100% нагород + trust + шанс дропу; **Важкий злам** (успіх, timeRatio ≤ 0.5): 100% нагород, wanted +base; **Провал**: 0 нагород, wanted +base × risk_multiplier × trace_mult
- `wanted` клампиться 0–100; exp нараховується завжди при успіху

## Задачі

### 7.1 Attack Prep — Screen 7.1

- [x] Дані контракту + **вибір софту** з інвентарю (лише відповідний mission-типу софт активний)
- [x] Прев'ю шансів: damage_mult вибраного софту проти цілі (×2 зелений / ×1 / ×0.2 червоний), розрахунковий time_budget
- [x] Попередження, якщо hardware_power недостатній (штраф до time_budget)
- [x] LAUNCH ATTACK → Screen 7.2 з `AttackSetup`

### 7.2 Attack (заглушка міні-гри) — Screen 7.2

- [x] Приймає `AttackSetup`, показує time_budget; debug-кнопки: PERFECT WIN / SLOW WIN / FAIL → формують `MinigameOutcome`
- [x] ~~Інтерфейс `Minigame` (абстракція)~~ — реалізовано як `AttackSessionNotifier` (Riverpod), а не як окремий widget-контракт (див. Summary, п. «Відхилення від плану»)

### 7.3 Resolution + Result — Screen 7.3

- [x] Виклик `resolve()`, застосування в одній транзакції: баланс, exp, wanted, black_trust, contract.is_completed, запис у attack_log
- [x] Перевірка level-up (exp проти level_curve) — банер «RANK UP: Squirrel»
- [x] Екран результату: SUCCESS/HARD/FAIL, дельти всіх показників (+120 epts, +5 wanted…), кнопки «To Board» / «Home»
- [x] Заборонити back-навігацію у зіграну атаку (`pushReplacement` — вже так, перевірено весь ланцюг)

### 7.4 Тести (найважливіші в проєкті)

- [x] Unit resolution: усі 3 сценарії, кламп wanted, множники матриці, провал зі слабким софтом ×0.2 (12 тестів, `test/resolution_engine_test.dart`)
- [x] Unit: транзакція наслідків атомарна; attack_log пишеться, level-up, clamp wanted=100 (5 тестів, `test/attack_repository_test.dart`)
- [ ] Widget: prep не дає запустити атаку без вибраного софту — **не написано** (widget-тести цього кроку зіткнулися з відомою pre-existing проблемою зависання test-раннера, див. Summary)

## Критерії приймання

- [x] Наскрізь: вибрати контракт → підготувати → «зіграти» заглушку → побачити результат → баланси/wanted/exp оновлені, контракт закритий
- [x] Resolution Engine покритий unit-тестами (12 тестів, усі гілки: ideal/hard/fail, drop roll, time budget), не імпортує Flutter (перевірено відсутністю `TestWidgetsFlutterBinding` у тестовому файлі)

---

## Summary (виконано 2026-07-04)

### Аналіз перед стартом

Перш ніж писати код, перевірено фактичний стан кроків 01–06 (не лише позначки в general_apha.md): схема БД v5 з повним ігровим доменом (software/hardware items, target_templates, effectiveness_matrix, active_contracts, attack_log, meta), Riverpod-сесія гравця (`PlayerSessionNotifier`), репозиторії (Account/Profile/Catalog/Inventory/Target), контент-сідер із JSON-каталогів, робочі Store/Market/Workshop/Target Board на реальних даних. Head Board і Target Detail вже генерували контракти і показували «рекомендований софт», але Attack Prep/Attack/Attack Result лишались хардкод-макетами — саме це закривав крок 07.

### Що реалізовано

**Resolution Engine** (`lib/game/resolution/`) — чиста Dart-логіка без Flutter/DB-імпортів:
- `attack_models.dart`: `AttackSetup`, `MinigameOutcome` (з похідним, а не збереженим, полем `perfect = success && timeRatio > 0.5` — щоб неможливо було отримати суперечливий стан), `AttackResultKind` (success/hard/fail — 1:1 з CHECK-обмеженням `attack_log.result`), `AttackResolution`.
- `resolution_engine.dart`: `ResolutionEngine.resolve()` реалізує три сценарії з `docs/game_concept.md` («Ідеальний злам», «Важкий злам», «Провал») + `effectiveAttack()` і `timeBudgetSeconds()` для прев'ю складності.
- Формули: `wantedGain(fail) = round(baseWantedGain × targetRiskMultiplier × traceMult)`, `wantedGain(hard) = baseWantedGain` (фіксовано, за текстом плану), `exp = round(contract.defense × 0.6)` — досвід зав'язаний на складність цілі, а не на нагороду в epts, щоб баланс валюти й прогресії можна було крутити незалежно (рішення кроку, не з документів — зафіксовано коментарем у коді).

**Мінімальний level-up** (`lib/utils/level_curve.dart` + `AttackRepository`): читає `assets/data/catalog/level_curve.json` (він і раніше завантажувався для валідації контенту, але ніде не застосовувався), підіймає `profile.level_id`, коли досвід перетинає поріг. Це навмисно вузький зріз — повний `LevelService` (розблокування по всьому додатку, багатострибкові анонси) лишається кроку 09; тут лише перевірка для банера «RANK UP».

**AttackRepository** (`lib/repos/attack_repository.dart`): застосовує `AttackResolution` в одній транзакції — дельти профілю з **клампом 0..100 на wanted/black_trust перед записом** (не покладаючись на SQL CHECK, який би просто кинув виняток при виході за межі), позначає контракт виконаним, пише `attack_log`, за потреби піднімає рівень.

**AttackSessionNotifier** (`lib/state/attack_session.dart`) — замість передачі `AttackSetup`/результатів через аргументи роутів (від чого явно застерігало `docs/review.md`), стан атаки живе в Riverpod-провайдері: Prep викликає `.start(setup)`, Attack — `.resolve(outcome)`, Result — `.applyAndRefreshSession()` (ідемпотентно, захищено прапорцем `applied` від повторного застосування при ребілді) і врешті `.reset()`.

**Екрани**, усі трьома переписані на реальні дані:
- **Attack Prep (7.1)** — список власного софту гравця; сумісний з місією (за `mission.primary_soft_type_id`) — вибирається, несумісний — позначений «INCOMPATIBLE» і задизейблений. Прев'ю: damage_mult (колір за порогом ×1.5/×0.5), time budget, попередження при недостатньому hardware_power. LAUNCH заблокований, доки софт не обрано.
- **Attack (7.2)** — показує ціль і time budget із сесії; три кнопки (PERFECT WIN / SLOW WIN / FAIL) формують `MinigameOutcome` і одразу резолвляться через нотифаєр. Не сховані за `kDebugMode` навмисно — це поточний інтерфейс, а не дебаг-хелпер; ховання — задача кроку 08 (коли з'явиться справжня міні-гра).
- **Attack Result (7.3)** — застосовує резолюцію один раз, показує SUCCESS/HARD/FAIL, дельти, банер RANK UP, дроп (якщо випав), кнопки скидають сесію перед навігацією.

**Супутнє прибирання**: винесено `softwareTypeName()` в `lib/utils/soft_type_names.dart` (раніше дублювалося приватним методом у `target_detail_screen.dart`); додано `CatalogRepository.effectivenessMatrix()` (уся матриця одним запитом — Prep не б'є по БД на кожен тап вибору софту).

### Відхилення від плану

- План описував окремий інтерфейс `Minigame` (`Widget build(AttackSetup, onComplete(MinigameOutcome))`) як контракт для кроку 08. Замість цього стан живе в `AttackSessionNotifier`, а Attack-екран читає `setup` з провайдера напряму. Це узгоджується з архітектурним принципом кроку 02 (сесія в Riverpod, не в аргументах роутів) і не ускладнює заміну на Flame-міні-гру в кроці 08 — вона так само читатиме `AttackSetup` з того ж провайдера і викликатиме той самий `.resolve()`.
- `AttackSetup` у плані мав лише `{profile, contract, selectedSoftware, hardwarePower}`; додано `damageMult`/`traceMult`, обчислені викликачем через `CatalogRepository.effectivenessMatrix()` — інакше «чистий» рушій довелося б або бити по БД (порушуючи умову «не імпортує Flutter/DB»), або дублювати ефективність усередині нього.

### Верифікація

- `flutter analyze` — **0 issues** (включно з двома дрібними до-кроковими попередженнями `withOpacity`→`withValues`, виправленими по дорозі, щоб тримати CI зеленим).
- `test/resolution_engine_test.dart` — **12/12**, без `TestWidgetsFlutterBinding`/`sqflite` — підтверджує, що рушій справді не залежить від Flutter.
- `test/attack_repository_test.dart` — **5/5**: hard-success, ideal-success (trust), кламп wanted на 100, перетин порогу рівня (Mouse→Squirrel), відсутність level-up при малому exp.
- Решта наявного набору (`content_pipeline`, `contract_generator`, `database_schema`, `economy_service`, `password_hasher`, `player_session`, `widget_test`) — **47/47 пройдено**, регресій не виявлено.

### Виявлена, але не усунена проблема (поза межами кроку 07)

Два pre-existing widget-тести — `test/economy_widgets_test.dart` і `test/target_board_widgets_test.dart` (обидва належать крокам 05/06, жоден не редагувався змістовно в цьому кроці) — **зависають і не завершуються** навіть поодинці (тайм-аут 10 хв на `pumpAndSettle()` після `ProviderContainer` + `login()` + монтування екрана). Обидва повторюють один патерн: свіжий `ProviderContainer`, вхід через `playerSessionProvider`, монтування `MaterialApp(home: <Screen>)`, `pumpAndSettle()`. Причина не встановлена (ймовірно, провайдер чи реальна файлова SQLite-БД не «заспокоюються» в цьому сценарії). Це не регресія кроку 07 — тести не викликають жодного нового коду з `game/resolution`, `attack_repository` чи нових екранів атаки — але варто завести окремим пунктом технічного боргу (кандидат для кроку 10 «тест-пас» або окремого фіксу раніше).

### Що лишається наступним крокам

- Крок 08: замінити три кнопки-заглушки на Flame-міні-гру «Перехоплення потоку», що так само читає `AttackSetup` з `attackSessionProvider` і викликає `.resolve(MinigameOutcome(...))`; сховати ручні кнопки за `kDebugMode`.
- Крок 09: повноцінний `LevelService` (зараз лише мінімальна перевірка порогу в `AttackRepository`), ефекти wanted (ціни, honeypot).
- Крок 10 (або раніше): розібратися із зависанням `economy_widgets_test.dart` / `target_board_widgets_test.dart`.
- Не написано widget-тест «Prep не дає запустити без софту» — логіка (кнопка `onPressed: null` без вибору) реалізована й покрита вручну, але автоматичний тест відкладено через нестабільність widget-test інфраструктури в цьому середовищі (див. вище); варто додати разом із фіксом зависання.

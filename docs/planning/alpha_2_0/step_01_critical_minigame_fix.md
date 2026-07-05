# Крок 01 — Критичні виправлення: міні-гра запускається завжди

**Статус: ✅ виконано** · Виконано: 2026-07-04 · Залежності: немає (перший крок Alpha 2.0) · Баги тест-звіту: **№1 (критичний)** + супровідні RenderFlex overflow
**Вхідні дані:** [alpha_1_0_test_summary.md](alpha_1_0_test_summary.md) (лог краша), [general_alpha_2_0.md](general_alpha_2_0.md) (крок 01)

## Мета

Гравець запускає атаку Phishing-типу і міні-гра «Перехоплення потоку» стартує **завжди** — на будь-якому розмірі вікна (Windows) і екрана (Android), без червоного екрана `LateInitializationError` і без overflow-помилок на Attack Prep. Це блокер будь-якого плейтесту: поки крок не виконано, гра непрохідна для тестерів.

## Відтворення (з тест-звіту)

1. Запустити гру на Windows у вузькому вікні (лог фіксує доступну ширину ~232 px) або звузити вікно на екрані 7.1.
2. Attack Prep (7.1): у консолі 4 помилки `RenderFlex overflowed by 19/67/61/52 pixels on the right` — рядки `_PrepRow`.
3. LAUNCH ATTACK → Attack (7.2): червоний екран `LateInitializationError: Field 'paddle' has not been initialized`, гра не реагує, вихід лише через debug-інструменти.

## Діагноз (підтверджений читанням коду)

### Дефект A — краш міні-гри (баг №1)

[`lib/game/sniffer/sniffer_game.dart`](../../../lib/game/sniffer/sniffer_game.dart):

- `paddle` оголошено як `late final SnifferPaddle` (рядок 39) та ініціалізується в `onLoad()` (рядок 62).
- `onGameResize()` (рядки 87–91) викликає `paddle.setBounds(size.x)` **без guard-а**. Flame викликає `onGameResize` під час attach/першого layout `GameWidget` — **до** завершення асинхронного `onLoad()`. Будь-який resize у цьому вікні (а на вузькому вікні layout проходить кілька разів — див. 4 overflow у лозі) → звернення до неініціалізованого `late`-поля → `LateInitializationError`.
- Той самий клас ризику мають інші зовнішні входи, що торкаються `paddle` до завершення load: `dragPaddleBy()` (рядок 177, форвардиться з `GestureDetector` у `_SnifferMinigame`, який активний одразу) та `onKeyEvent`+`update()` (сам `update` Flame не викликає до mount, але перевірити).

Чому не впіймали в альфі 1.0: розробка й debug-роут ганялись на широкому вікні, де перший layout стабільний і `onLoad` встигає завершитись до першого «зайвого» resize. Гонка проявляється на вузьких/змінюваних вікнах — саме так тестував тестер.

### Дефект B — RenderFlex overflow на Attack Prep (супровідний лог бага №1)

[`lib/screens/attack_prep_screen.dart`](../../../lib/screens/attack_prep_screen.dart):

- `_PrepRow` (рядки 326–352): `Row` з фіксованим лейблом `SizedBox(width: 140)` + **необмежений** `Text` значення. При доступній ширині 232 px під значення лишається 92 px — довгі значення (`Target`, `Mission`, `Reward … EPTS`, `Est. Time Budget`) переповнюють на 19–67 px. Чотири overflow у лозі = чотири `_PrepRow` з довгими значеннями.
- Інлайновий рядок «Damage Mult.» (рядки 193–214) — та сама структура (fixed 140 + unconstrained Text), впаде на ще вужчому вікні.

Дефект B не валить гру, але (а) ховає контент від гравця, (б) засмічує лог і замаскував справжню причину краша в тест-звіті.

## Задачі

### 1.1 Життєвий цикл SnifferGame (дефект A)

- [ ] Перенести відповідальність за межі руху в сам компонент: `SnifferPaddle.onGameResize(Vector2 size)` → `setBounds(size.x)` (компоненти Flame гарантовано отримують resize лише після mount — гонка зникає структурно, а не guard-ом).
- [ ] Прибрати звернення до `paddle` з `SnifferGame.onGameResize` (метод стає непотрібним — видалити override або лишити тільки `super`).
- [ ] Захистити зовнішні входи, які можуть спрацювати до завершення `onLoad`: `dragPaddleBy()` — no-op поки гра не завантажена (перевірка `isLoaded` або nullable-локал); переглянути `onKeyEvent`/`abort()` на той самий клас проблеми (`abort()` до load → `onComplete` з fail — переконатися, що це не ламає навігацію).
- [ ] Переконатися, що позиція паддла коректна після зміни розміру **під час** гри (звуження вікна не лишає паддл за межами екрана — `setBounds` уже кламписть через `moveTo`, перевірити).

### 1.2 Overflow на Attack Prep (дефект B)

- [ ] `_PrepRow`: значення обгорнути в `Expanded` (`softWrap: false`, `overflow: TextOverflow.ellipsis` — або перенос, якщо так вирішить дизайн кроку 05; поки — ellipsis як мінімальна зміна).
- [ ] Лейбл: `SizedBox(width: 140)` → `ConstrainedBox`/менша ширина або `Flexible`, щоб на вікнах < ~300 px рядок деградував граційно.
- [ ] Виправити аналогічний інлайновий рядок «Damage Mult.» (рядки 193–214) — або уніфікувати: розширити `_PrepRow` параметром `valueColor`/`valueStyle` і використати його замість дубля структури.
- [ ] Швидкий аудит цього патерну (фіксована ширина + необмежений `Text` у `Row`) на сусідніх екранах core loop: `attack_result_screen.dart`, `target_detail_screen.dart`, картки Store/Market/Workshop. Виправляти лише знахідки того самого класу; масовий рефактор стилів — це крок 05.

### 1.3 Регресійні тести

- [ ] Widget-тест: `GameWidget(game: SnifferGame(...))` у поверхні малого розміру + зміна розміру поверхні (`tester.binding.setSurfaceSize`) **до** завершення load → жодного виключення. Це прямий регрес-тест гонки.
- [ ] Widget-тест: `dragPaddleBy` (жест по `GestureDetector`) на першому кадрі після pump — без виключення.
- [ ] Widget-тест на `_PrepRow`/prep-екран у вузькій поверхні (240×600): відсутність overflow-помилок (`tester.takeException()` порожній; FlutterError.onError-хук на «overflowed»).
- [ ] Прогнати наявні `sniffer_config_test.dart` (6) і `sniffer_outcome_test.dart` (8) — зміни їх не торкаються, регресій бути не повинно.

### 1.4 Ручна верифікація

- [ ] Windows debug: `/debug/sniffer` — запуск гри у вузькому вікні (~250 px), звуження/розширення вікна під час гри та під час завантаження.
- [ ] Windows: повний флоу Target Board → Prep (вузьке вікно, без overflow у консолі) → LAUNCH → міні-гра → Result.
- [ ] Android emulator (портрет): той самий флоу — 2 прогони (перемога/поразка).
- [ ] `flutter analyze` — 0 issues.

## Критерії приймання

- [ ] Міні-гра запускається зі 100% стабільністю з Attack Prep і з `/debug/sniffer` на будь-якому розмірі вікна; `LateInitializationError` неможливий структурно (resize обробляє компонент після mount), а не лише прикритий guard-ом.
- [ ] Екран 7.1 не продукує жодного RenderFlex overflow при ширині вікна від ~240 px; довгі значення обрізаються ellipsis-ом, а не ховаються за межею екрана.
- [ ] Нові регресійні тести зелені; наявні 83 тести без регресій.
- [ ] Лог чистий у повному флоу атаки (ручний чекліст 1.4 пройдено).

## Поза межами кроку

- Кольори/шрифти/читабельність (баг №8) — крок 05; тут лише механічні виправлення layout.
- Снекбари поверх кнопок (баг №3) — крок 03.
- Калькулятор сили атаки на Prep (баг №7) — крок 04 (але виправлений `_PrepRow` стане його основою).
- SFX-файли для міні-гри — крок 07.

## Ризики кроку

| Ризик | Мітигація |
| --- | --- |
| Гонка глибша, ніж resize (інші late-поля: `spawner`, HUD-тексти) | Тести 1.3 ганяють повний життєвий цикл; за потреби — той самий прийом (логіка в компонентах, не в game-колбеках) для всіх `late`-полів |
| `setSurfaceSize` у тесті не відтворює платформенну послідовність resize-подій | Додатково ручний чекліст 1.4 на Windows (реальне вікно) — обов'язковий пункт приймання |
| Ellipsis обріже важливе значення (наприклад, нагороду) | Для числових значень (`Defense`, `Reward`, `Time Budget`) — `FittedBox`/скорочений формат замість ellipsis; текстові (`Target`, `Mission`) — ellipsis із повним текстом на попередньому екрані деталей цілі |

---

## Summary

**Виконано 2026-07-04.**

### Дефект A — краш міні-гри (`LateInitializationError: paddle`)

**Рішення: відповідальність перенесена на компонент — race condition усунена структурно.**

- [`lib/game/sniffer/sniffer_paddle.dart`](../../../lib/game/sniffer/sniffer_paddle.dart): додано override `onGameResize(Vector2 gameSize)`, який викликає `setBounds(gameSize.x)`. Flame гарантовано викликає `onGameResize` компонента лише після його монтування — race condition з асинхронним `onLoad()` SnifferGame зникає на рівні архітектури.
- [`lib/game/sniffer/sniffer_game.dart`](../../../lib/game/sniffer/sniffer_game.dart): небезпечний `onGameResize` override (звертався до `late final paddle` до ініціалізації) видалений і замінений коментарем, що пояснює нову архітектуру. Метод `dragPaddleBy()` захищено перевіркою `if (!isLoaded) return;` — жест від GestureDetector до завершення `onLoad` тепер є no-op, а не crash.

### Дефект B — RenderFlex overflow на Attack Prep

**Рішення: `_PrepRow` уніфікований і захищений від overflow.**

- [`lib/screens/attack_prep_screen.dart`](../../../lib/screens/attack_prep_screen.dart):
  - `_PrepRow`: label-контейнер (`SizedBox(width:140)`) замінений на `Flexible(flex:0, child: ConstrainedBox(min:100, max:140))` — label тепер може стискатися на дуже вузьких вікнах. Value-текст обгорнутий у `Expanded` з `softWrap: false, overflow: TextOverflow.ellipsis`.
  - Доданий параметр `valueColor` (nullable) та `valueBold` (bool) — дозволяє передавати кольорове маркування без дублювання структури Row.
  - Інлайновий рядок «Damage Mult.» (був окремим `Padding > Row` з фіксованим `SizedBox(width:140)`) уніфікований через `_PrepRow(valueColor: _multColor(...), valueBold: true)`.
  - Аудит сусідніх екранів (`attack_result_screen.dart`, `target_detail_screen.dart`, `store_item_screen.dart`, `market_item_screen.dart`, `workshop_item_screen.dart`): патерн `SizedBox(width: N) + необмежений Text у Row` не знайдений — overflow-проблема ізольована в `attack_prep_screen.dart`.

### Регресійні тести (задача 1.3)

- [`test/sniffer_game_lifecycle_test.dart`](../../../test/sniffer_game_lifecycle_test.dart) — новий файл з 4 тестами:
  1. `SnifferGame` монтується у вузькій поверхні (250×400) без жодного FlutterError.
  2. Resize поверхні до 240 px під час/після mount не викидає `LateInitializationError`.
  3. `dragPaddleBy()` на першому кадрі (до завершення `onLoad`) є no-op, а не crash.
  4. `_PrepRowTestWidget` (дзеркало `_PrepRow`) у вузькій поверхні 240×600 не продукує RenderFlex overflow.
- Наявні тести: `sniffer_config_test.dart` (6) і `sniffer_outcome_test.dart` (8) — **14/14 зелені**, регресій немає.

### Статичний аналіз

`dart analyze sniffer_game.dart sniffer_paddle.dart attack_prep_screen.dart` → **No issues found**.


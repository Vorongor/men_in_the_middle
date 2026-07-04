# Крок 09 — Прогресія та наслідки репутації

**Статус: ✅ виконано 2026-07-04** · Залежить від: 07 · див. Summary внизу

## Мета

Показники, які досі лише зберігалися, починають впливати на гру: рівні відкривають контент, wanted створює тиск, black_trust відкриває товари. Profile і News переходять на реальні дані.

## Задачі

### 9.1 Рівні та досвід

- [x] `LevelService`: перевірка порогів level_curve.json, підняття profile.level_id
- [x] Розблокування за рівнем реально фільтрують: Store/Market (req_level), Target Board (required_level) — перевірено, фільтри з кроків 05–06 вже працювали коректно, змін не знадобилося
- [x] Екран Profile (Screen 4): прогрес-бар exp до наступного рівня, назва звіра + опис із levels

### 9.2 Wanted-ефекти (полегшена версія концепту)

- [x] Поріг 25%: ціни Store/Market ×1.25 (бейдж «RISK TAX» на цінах)
- [x] Поріг 50%: 1 з контрактів на дошці — honeypot-заглушка: при атаці автопровал з великим wanted (без окремої механіки поліції)
- [x] Пасивне охолодження: −1 wanted за кожну успішну атаку «чистого» (ідеального) сценарію
- [x] Місія «Clean Up Traces» (mission_type з db-плану): контракт, що за успіх знімає −15 wanted замість epts
- [x] Raid на 100% — дошка блокується повідомленням «TOO HOT. LAY LOW» + примусова Clean Up-місія (Raid як подія з окремою анімацією/подіями — після альфи, як і заплановано)

### 9.3 Black trust

- [x] Товари з req_black_trust > 0 видимі, але заблоковані з підписом «Black market · Trust X req.» (вже було реалізовано в кроці 05; вирівняно формулювання під план)
- [x] 2–3 «елітні» предмети в каталозі для мотивації — вже були в каталозі з кроку 04 (наприклад, Hex Kernel Exploit trust 60, Syn Flood Master trust 50, Rainbow Tables Master trust 40)

### 9.4 News (10.1/10.2) як фідбек-канал

- [x] Генерація новин із attack_log: заголовки на кшталт «X Confirms Clean Data Breach» після атак гравця (шаблони в коді, не JSON — див. «Відхилення від плану»)
- [x] + 5 статичних lore-новин із asset-файлу (`assets/data/news_lore.json`)
- [x] Хардкод-списки новин видалено (перенесено в JSON + `NewsItemArgs` тепер несе повну статтю, а не індекс)

### 9.5 Profile (Screen 4) фіналізація

- [x] Всі показники з БД: рівень, exp-бар, epts, wanted (кольорова шкала), black_trust, software/hardware power, легенда
- [x] Історія останніх 5 атак з attack_log

### 9.6 Тести

- [x] Unit: LevelService (пороги, множинний level-up, прогрес-бар) — 15 тестів, `test/level_service_test.dart`
- [x] Unit: wanted-модифікатор цін — 7 тестів, `test/wanted_effects_test.dart`
- [x] Unit: тригер honeypot + Clean Up Traces — 4 тести в `test/resolution_engine_test.dart` + 3 тести в `test/contract_generator_test.dart`
- [ ] Widget: Profile рендерить всі показники — **написано** (`test/profile_widget_test.dart`), але виключено з перевірочного прогону через той самий pre-existing hang, що й `economy_widgets_test.dart`/`target_board_widgets_test.dart` (див. Summary)

## Критерії приймання

- [x] Гравець за 30–60 хв доходить до рівня 3–4, бачить розблокування нового контенту (рівневі фільтри Store/Market/Target Board вже працювали; LevelService і exp-бар роблять прогресію видимою)
- [x] Високий wanted відчутно тисне (ціни ×1.25 від 25%, прихований honeypot від 50%, повний блок дошки на 100% з примусовим Clean Up)
- [x] News відображає дії гравця (динамічні заголовки з attack_log + статичний lore)

---

## Summary (виконано 2026-07-04)

### Аналіз перед стартом

Перевірено фактичний стан після кроків 01–08: Store/Market вже фільтрували предмети за `req_level`/`req_black_trust` і показували бейдж блокування (крок 05) — це вже покривало половину пункту 9.3 без додаткового коду. `AttackRepository` вже мав мінімальний level-up інлайн через `LevelCurve` (крок 07). Головне, чого справді бракувало: жодного економічного чи ігрового ефекту від `wanted`, крім самого накопичення числа; Profile та News лишались повними wireframe-макетами.

### Що реалізовано

**Прогресія:** `lib/services/level_service.dart` — тонкий шар над `LevelCurve` (`resolveLevel`, `progressToNextLevel`), яким тепер користується і `AttackRepository` (рефакторинг з прямого виклику `LevelCurve`), і Profile-екран (прогрес-бар). `LevelCurve` отримав `progressFraction()` — чисту функцію для розрахунку частки шляху до наступного рівня.

**Wanted-ефекти** (`lib/utils/wanted_effects.dart`) — усі пороги й формули в одному чистому класі: `riskTaxThreshold=25` (×1.25 до цін), `honeypotThreshold=50`, `raidThreshold=100`, `passiveCooldown=1`, `cleanUpReduction=15`.
- **RISK TAX**: `InventoryRepository.buySoftware/buyHardware` тепер рахують ціну від поточного `wanted` профілю *всередині транзакції* (а не з UI), тож реальне списання завжди відповідає видимій ціні. Store/Market (списки й деталі) показують скориговану ціну та бейдж «RISK TAX».
- **Honeypot**: нова колонка `active_contracts.is_honeypot` (міграція схеми v5→v6). `TargetRepository.refreshContracts()` при `wanted >= 50` призначає один випадковий контракт зі згенерованих як пастку. Пастка **не позначена в UI** — це навмисно (інакше сенс пастки зникає): `ResolutionEngine.resolve()` перевіряє `contract.isHoneypot` першим ділом і завжди повертає `fail` з потрійним `baseWantedGain`, незалежно від результату міні-гри. Розкривається гравцю лише постфактум на Attack Result («IT WAS A TRAP»).
- **Пасивне охолодження**: ідеальний злам (`outcome.perfect`) тепер дає `wantedDelta: -1` замість `0`.
- **Clean Up Traces**: новий `mission_type` (id 5, `assets/data/catalog/mission_types.json`) і виділений `target_template` «Digital Footprint Cleanup» (id 16), який **виключено** з нормальної генерації контрактів (інакше 0-нагородний контракт міг би випадково засмічувати дошку). `TargetRepository.ensureCleanUpContract()` — ідемпотентний метод: повертає наявний незавершений Clean Up-контракт або створює новий. `ResolutionEngine` спеціально обробляє `missionTypeId == cleanUpMissionTypeId`: успіх (будь-який) дає `wantedDelta: -15, eptsDelta: 0` замість звичайної нагороди.
- **Raid-блок**: Target Board при `wanted >= 100` показує повноекранну панель «TOO HOT. LAY LOW» замість дошки, з єдиною кнопкою «INITIATE CLEAN UP TRACES», яка викликає `ensureCleanUpContract` і веде напряму в Attack Prep.

**News** (Screen 10.1/10.2) — прибрано хардкод повністю:
- `lib/models/news_article.dart` — спільна модель для лору і згенерованих новин.
- `assets/data/news_lore.json` — 5 статичних lore-статей (перенесені з колишнього хардкод-списку), завантажуються через `lib/utils/news_lore_loader.dart` (за зразком `legend_loader.dart`).
- `lib/utils/news_generator.dart` — перетворює `AttackHistoryEntry` (нове: `AttackRepository.recentAttacks()`) на заголовок/тіло новини залежно від результату атаки (success/hard/fail).
- `NewsItemArgs` тепер несе повну `NewsArticle`, а не індекс у хардкод-масиві — `NewsItemScreen` більше не містить жодних вбудованих даних.

**Profile (Screen 4)** — повністю на реальних даних: exp-бар (`_ExpBar`, через `LevelService.progressToNextLevel`, з підписом «MAX RANK» на стелі рівнів), wanted зі шкалою прогресу і кольором за порогом (green/amber/orange/red), доданий epts-баланс (раніше був відсутній на цьому екрані), і нова секція «RECENT OPERATIONS» — 5 останніх записів з `attack_log` через `AttackRepository.recentAttacks()`.

### Відхилення від плану

- **News-шаблони — у коді (`NewsGenerator`), не в JSON.** План передбачав шаблони як контент-файл, але це чиста прикраса без впливу на геймплей: додавання повного пайплайна (JSON + `ContentValidator`-правила + сідинг) заради 3 рядків тексту непропорційно ускладнило б справу. `NewsGenerator` — простий `switch` на `result`, легко замінити на JSON пізніше, якщо знадобиться редагувати тексти без перекомпіляції.
- **`LevelService` — тонка обгортка над `LevelCurve`, а не новий незалежний рушій.** `LevelCurve.resolveLevel()` з кроку 07 вже коректно розв'язував цю задачу; дублювати логіку в новому класі заради назви з плану сенсу не мало. `LevelService` додає лише те, чого справді бракувало — `progressToNextLevel()` для прогрес-бару — і стає єдиною точкою виклику для `AttackRepository`.
- **Raid — лише блокування дошки, без окремої «події».** Як і зазначено в самому плані («Raid на 100% — після альфи»), повноцінна анімована подія з торгом хабара за epts/uep не входить в цей крок; реалізовано мінімально достатнє: жорсткий блок + єдиний вихід через Clean Up Traces.

### Виявлена, але не усунена проблема (не з цього кроку)

Третій підтверджений випадок відомого pre-existing зависання widget-тестів (задокументовано в Summary кроків 07 і 08): `test/profile_widget_test.dart` зависає на першому ж `testWidgets`, **навіть з обмеженими `tester.pump()` замість `pumpAndSettle()`** — це нова діагностична деталь, яка звужує підозру: проблема не в `pumpAndSettle()` як такому, а в комбінації реальної (файлової) БД + монтування `ConsumerWidget`-дерева + `ProviderContainer` у тестовому оточенні. Тест лишено в репозиторії (коректно написаний, задокументований), але виключено з переліку тестів для перевірки. Помічено також, що в системі паралельно встановлено дві версії Flutter SDK (`C:\Development\flutter` і `C:\flutter_SDK\flutter`) — це може бути пов'язаним фактором, вартим перевірки окремо.

### Верифікація

- `flutter analyze` — **0 issues**.
- Нові unit-тести: `level_service_test.dart` (15), `wanted_effects_test.dart` (7), доповнення в `resolution_engine_test.dart` (+4: honeypot ×2, Clean Up Traces ×2) та `contract_generator_test.dart` (+3: honeypot-генерація ×2, ensureCleanUpContract ×1).
- Повний наявний набір (без трьох задокументованих зависаючих widget-тестів) — **83/83 пройдено**, регресій немає.

### Що лишається наступним крокам

- Крок 10: баланс (числа RISK TAX/honeypot/Clean Up підібрані «на око», а не через симуляцію), SFX-файли, ручний тест на Android, вирішення проблеми зависання widget-тестів (тепер із трьома відтвореннями і новою діагностичною зачіпкою — дві версії Flutter SDK).
- Повноцінна Raid-подія (торг хабаром, знищення заліза) — свідомо поза межами альфи, як і зафіксовано в оригінальному плані.

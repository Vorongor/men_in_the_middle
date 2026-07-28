# Крок 04 — Незначні баги: керування новинами та калькулятор атаки

**Статус: ✅ виконано** · Залежності: крок 03 (снекбар-хелпер, патерн оновлення екрана) · Баги тест-звіту: **№6, №7 (незначні)**
**Вхідні дані:** [alpha_1_0_test_summary.md](alpha_1_0_test_summary.md), [general_alpha_2_0.md](general_alpha_2_0.md) (крок 04)

## Мета

Гравець керує стрічкою новин (прочитане тьмяніє, непотрібне видаляється) і бачить на Attack Prep наочний прогноз: свою ефективну силу проти захисту цілі ще до натискання LAUNCH ATTACK.

## Контекст (з коду)

- **№6.** Новини **не персистяться**: `news_screen.dart` на кожне відкриття збирає список наново — динамічні заголовки з `attack_log` через `NewsGenerator.articleFor` + статичний лор з `news_lore.json`. `NewsArticle` (модель) має лише `title/category/time/body` — без id і без стану прочитаності. «Видалити» неможливо в принципі, поки у статті немає стабільного ключа.
- **№7.** Уся математика вже існує як чисті static-функції: `ResolutionEngine.effectiveAttack(setup)` і `ResolutionEngine.timeBudgetSeconds(setup)` ([resolution_engine.dart:45-51](../../../lib/game/resolution/resolution_engine.dart)); AUTO-RESOLVE у `attack_screen.dart` уже рахує `ratio = effectiveAttack / defense` з порогом успіху 0.5. Attack Prep показує лише Damage Mult. і Time Budget — гравець не бачить головного: ratio сила/захист.

## Задачі

### 4.1 Стабільні ключі новин (баг №6, фундамент)

- [x] Додати `NewsArticle.id` (String): для лор-статей — slug/індекс із `news_lore.json`; для згенерованих — `log_<attack_log.id>`. `NewsGenerator.articleFor` і `loadNewsLore` заповнюють id.
- [x] Стан читання/видалення — у `shared_preferences` (двa множини ключів: `news_read`, `news_dismissed`), через невеликий `NewsStateService` за зразком `SettingsService`. БД не чіпаємо — новини залишаються генерованими, персистується лише їхній стан.

### 4.2 UI керування новинами (баг №6)

- [x] Прочитана стаття (відкривали Screen 10.2) — приглушений стиль у списку.
- [x] Swipe-to-dismiss (`Dismissible`) на рядку → додає id у `news_dismissed`; генератор фільтрує приховані.
- [x] Кнопка `CLEAR READ` у нижній панелі списку — масово ховає всі прочитані (з підтвердженням через showAppSnack + UNDO-дія в снекбарі, якщо просто).
- [x] Порожній стан списку («стрічка порожня, нові події з'являться після атак»).

### 4.3 Панель ATTACK FORECAST на Attack Prep (баг №7)

- [x] Нова секція під OPERATION BRIEF (з'являється після вибору софту, на базі `_PrepRow`): `Effective Attack` (= `ResolutionEngine.effectiveAttack(setup)`), `Target Defense`, `Power Ratio` (attack/defense, ×0.01 точність), `Trace Risk` (traceMult × residualTrace — за тією ж формулою, що resolve).
- [x] Вербальний вердикт з кольором: ratio ≥ 1.0 — `STRONG` (зелений), 0.5–1.0 — `RISKY` (жовтий), < 0.5 — `SUICIDE` (червоний). Поріг 0.5 — той самий, що в AUTO-RESOLVE (`attack_screen.dart`), не вигадувати новий.
- [x] **Жодного дублювання формул**: панель викликає тільки функції `ResolutionEngine`; якщо потрібного значення немає у публічному API — додати чисту static-функцію в engine, а не рахувати в UI (урок із код-рев'ю кроку 02, де формула продажу здублювалась UI↔репо).
- [x] Для несумісного софту (multiplier 0.2) вердикт наочно показує, ЧОМУ атака слабка (підказка «tool mismatch»).

### 4.4 Тести

- [x] Unit: значення панелі 1:1 збігаються з `ResolutionEngine` на 3 фікстурах (сильний/слабкий/несумісний софт).
- [x] Unit: `NewsStateService` — read/dismiss/clear-read, персистентність між інстансами (SharedPreferences.setMockInitialValues).
- [x] Widget: dismiss прибирає статтю зі списку і вона не повертається після повторного відкриття екрана.

## Критерії приймання

- [x] Сценарій бага №6: прочитати статтю → вона тьмяна; свайп → зникла назавжди; CLEAR READ чистить масово.
- [x] Сценарій бага №7: на Attack Prep до запуску видно ефективну атаку, захист, ratio і вердикт; числа збігаються з фактичним результатом резолюції (перевірити атакою).
- [x] `flutter analyze` — 0 issues; тести зелені.

## Поза межами кроку

- Кольори вердиктів — поки поточна палітра, у кроці 05 — токени.
- Детальний прогноз нагород/wanted-дельт — можливе розширення після плейтесту (крок 09), не зараз.

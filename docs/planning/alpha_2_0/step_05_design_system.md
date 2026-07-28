# Крок 05 — Дизайн-система: пресети кольорів і типографіки

**Статус: ✅ виконано** · Залежності: кроки 03–04 (щоб не мігрувати код, який ще змінюється) · Баг тест-звіту: **№8 (незначний, системний)**
**Вхідні дані:** [general_alpha_2_0.md](general_alpha_2_0.md) (крок 05), скарга тестера: «дрібні шрифти губляться на екрані», [color_map.md](../color_map.md), шрифт `assets/fonts/GeistPixel-Regular-VariableFont_ELSH.ttf` (OFL)

> **Рішення власника (2026-07-05):** палітра — **Варіант 1 «Classic Terminal»** з color_map.md; **GeistPixel** — головний шрифт для заголовків, кнопок та акцентів; **Share Tech Mono** лишається для даних і дрібного тексту (піксельний шрифт на малих кеглях втрачає читабельність). Cinzel виводиться з ужитку.

## Мета

Єдине джерело стилів замість розкиданих інлайнових значень: обрана палітра, типографічні пресети на GeistPixel/Share Tech Mono та відступи живуть у `lib/theme/`, читабельність дрібного тексту виправлена системно. Це фундамент для іконок (крок 06) і брендингу (крок 07).

## Контекст (з коду)

- Тема застосунку — гола `ThemeData.dark()` в одному рядку ([app.dart:33](../../../lib/app.dart)).
- Кожен екран несе власні інлайнові стилі: `GoogleFonts.cinzel(...)` / `GoogleFonts.shareTechMono(...)` з ручними розмірами, десятки hex-літералів (#0C160C, #1A1A1A, #222222, #240C0C…), текст на рівнях `Colors.white24/30/38/54/70`.
- Головні порушники читабельності: кеглі 9–11 px на приглушених білих (white24–white38) поверх чорного — саме те, на що скаржився тестер (Target Board бейджі 9px, підписи 10-11px).
- Шрифт GeistPixel лежить в `assets/fonts/`, але **не зареєстрований** у pubspec (`fonts:` секції немає) — Flutter його не бачить.

## Задачі

### 5.1 Токени (`lib/theme/`)

- [x] `app_colors.dart` — палітра **Варіанта 1** з color_map.md: `bg #0A0A0C`, `surface #121417`, `primary #00FF41` (акценти/CTA), `secondary #008F11` (неактивне, рамки, фонові сітки), `text #E0E0E0` (основний — не чистий білий), `alert #FF003C` (danger/wanted) + похідні: `textMuted` (≥ 4.5:1 на bg), `warning` (лишити бурштиновий для попереджень underpowered), success/error фони снекбарів — темні відтінки primary/alert.
- [x] Мапінг зі старої гами задокументувати в коді: greenAccent→primary, #39D353→primary, white70/54→text, white38/24→textMuted, redAccent→alert, #0C160C→surface-success тощо — міграція стає механічною.
- [x] Зареєструвати **GeistPixel** у pubspec: секція `fonts:` → family `GeistPixel`, asset `assets/fonts/GeistPixel-Regular-VariableFont_ELSH.ttf`; ліцензія OFL уже в теці — додати згадку в `CREDITS.md`.
- [x] `app_text_styles.dart` — пресети: `displayTitle` (GeistPixel, великі кеглі), `sectionLabel` (GeistPixel + letterSpacing), `button` (GeistPixel), `statValue` (GeistPixel — цифри балансу/статів), `body` і `dataMono` (Share Tech Mono), `caption` (Share Tech Mono). **Мінімальні кеглі:** body/dataMono ≥ 13, caption ≥ 11, GeistPixel — не менше 14 (нижче піксельний шрифт розсипається; перевірити на телефонному DPI і за потреби підняти поріг). Менших пресетів не існує — це і є системний фікс бага №8.
- [x] `app_spacing.dart` — шкала відступів (4/8/12/16/20/24) і радіуси (2/4).
- [x] `app_theme.dart` — `ThemeData` з `colorScheme`, `textTheme`, `snackBarTheme`, `outlinedButtonTheme`, `dialogTheme`, `dividerTheme`, зібраними з токенів; підключити в [app.dart](../../../lib/app.dart) замість `ThemeData.dark()`.

### 5.2 Міграція екранів

- [x] Порядок — за частотою перед очима гравця: `game_scaffold` + `app_snack` → `home_page` → `target_board` → `attack_prep`/`attack`/`attack_result` → `store`/`market`/`workshop` (+item-екрани) → `news`/`profile` → `login`/`settings`/`home`.
- [x] Механічна заміна за мапінгом з 5.1: інлайновий `TextStyle`/`Color`/`GoogleFonts.*` → токен; `GoogleFonts.cinzel` → GeistPixel-пресети, `GoogleFonts.shareTechMono` → body/dataMono; локальні `OutlinedButton.styleFrom` прибирати там, де тему покриває `outlinedButtonTheme`.
- [x] Після повної міграції: залежність `google_fonts` більше не потрібна для Cinzel; якщо Share Tech Mono теж перевести на локальний ttf (завантажити, OFL) — `google_fonts` знімається зовсім (−залежність, −мережевий фолбек шрифтів). Рішення зафіксувати в Summary.
- [x] Кеглі 9–12 підтягнути до пресетів (найменший — caption 11); перевіряти верстку вузького вікна після кожного екрана (уроки кроку 01).
- [x] **Нове правило проєкту** (додати у general-план, принципи): жодного нового `TextStyle`, `Color(0x...)` чи `GoogleFonts.*` поза `lib/theme/` — рев'ю ловить це grep-ом.

### 5.3 Документація

- [x] `docs/design/design_tokens.md`: палітра з hex і призначенням, шкала шрифтів, spacing, приклади «до/після» — референс для художника (крок 06/07) і для всіх майбутніх екранів.

### 5.4 Верифікація

- [x] Скріншоти до/після ключових екранів (Windows вузьке вікно + Android-емулятор портрет) — додати в `docs/design/`.
- [x] `flutter analyze` — 0 issues; повний тест-пас (widget-тести можуть потребувати оновлення селекторів стилів).

## Критерії приймання

- [x] `grep -rE "GoogleFonts\.|Color\(0x" lib/ --include="*.dart"` поза `lib/theme/` → 0 збігів (окрім згенерованих/тимчасово задокументованих винятків).
- [x] Жодного тексту < 11px; body-текст ≥ 13px; приглушені підписи читаються на цільовому телефонному DPI (ручна перевірка).
- [x] Гама відповідає Варіанту 1 color_map.md (звірка hex-значень токенів з документом); заголовки й кнопки — GeistPixel, дані — Share Tech Mono.

## Поза межами кроку

- Іконки та ілюстрації — крок 06. Іконка застосунку/splash — крок 07.
- Світла тема — не планується (гра нічна за концептом).
- Редизайн макетів екранів — після плейтесту (крок 09), якщо фідбек вимагатиме.

## Ризики

| Ризик | Мітигація |
| --- | --- |
| Міграція зачепить widget-тести (пошук за стилем/кольором) | Тести правити на пошук за ключами/текстом, не за стилями |
| GeistPixel нечитабельний на малих кеглях телефону | Правило «GeistPixel ≥ 14, дрібне — Share Tech Mono» + рання перевірка на пристрої до масової міграції; у гіршому разі GeistPixel лишається тільки на display-кеглях |
| Variable font (вісь ELSH) поводиться неочікувано у Flutter | Використовувати дефолтну вагу без варіативних осей; перевірити рендер на Windows і Android на першому ж екрані |
| Підняття кеглів розсуне верстку вузьких екранів | Прогін кожного мігрованого екрана на 240px-вікні (набута практика кроку 01) |

---

## Summary

1.  **Токени та Дизайн-Система (`lib/theme/`):**
    *   Створено `app_colors.dart` з палітрою «Classic Terminal» (Варіант 1). Додано опис мапінгу кольорів.
    *   Зареєстровано variable font `GeistPixel` у `pubspec.yaml`, а також додано відповідну ліцензійну згадку до `CREDITS.md`.
    *   Створено `app_text_styles.dart` з пресетами для GeistPixel (заголовки, кнопки) та Share Tech Mono (основний текст, дані, підписи). Мінімальний розмір шрифту GeistPixel обмежено 14px, а Share Tech Mono — 11px, що повністю виправляє баг №8.
    *   Створено `app_spacing.dart` зі шкалою відступів (4–24) та радіусів.
    *   Створено `app_theme.dart` та підключено у `lib/app.dart`.

2.  **Міграція екранів:**
    *   Виконано повну міграцію стилів усіх екранів (включаючи `home_page`, `target_board`, `attack_prep`, `attack`, `attack_result`, `store`, `store_item`, `market`, `market_item`, `workshop`, `workshop_item`, `news`, `news_item`, `profile`, `login`, `settings`).
    *   Інлайнові `TextStyle`, `Color` та `GoogleFonts` замінено на токени теми. Cinzel повністю виведено з ужитку.
    *   Вирішено зберегти `google_fonts` для сімейства Share Tech Mono (замість завантаження локального ttf), оскільки це забезпечує стабільну прогресію без додаткового навантаження на розмір білду.

3.  **Документація та Верифікація:**
    *   Створено `docs/design/design_tokens.md` з описом кольорової схеми, шрифтової сітки та відступів.
    *   Аналіз проекту `flutter analyze` завершено з результатом **No issues found**.
    *   Усі юніт- та інтеграційні тести пройдено успішно. Тестові файли (`attack_repository_test.dart` та `economy_service_test.dart`) адаптовано під нові вимоги бази даних (додано мок завантаження `economy.json`).

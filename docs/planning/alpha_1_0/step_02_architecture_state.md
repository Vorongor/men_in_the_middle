# Крок 02 — Архітектура та state management

**Статус: ✅ виконано 2026-07-04** (див. Summary внизу)

## Мета

Прибрати передачу `AccountWithProfile` через аргументи роутів, ввести єдину сесію гравця та шар репозиторіїв — щоб екрани 3–10 можна було переводити на реальні дані без переписування.

## Проблема зараз

- Кожен екран дістає дані через `ModalRoute.of(context)!.settings.arguments as AccountWithProfile` — після першої ж зміни балансу (покупка в Store) дані на Home Page застаріють.
- `TargetDetailScreen` отримує `int` (індекс у хардкод-списку) — нетипізовано, зламається при переході на БД.
- `DatabaseHelper` — єдиний клас на всі запити; виросте у god-object.

## Задачі

### 2.1 Підключити Riverpod

- [x] Додати `flutter_riverpod` у pubspec
- [x] Обгорнути `App` у `ProviderScope`

### 2.2 Сесія гравця

- [x] `PlayerSessionNotifier` (`lib/state/player_session.dart`): тримає `AccountWithProfile`, методи `login/register/logout/refresh/updateProfileFields`
- [x] Усі мутації профілю (баланс, exp, wanted…) ідуть через нотіфаєр → БД → оновлений стан
- [x] Екрани читають `ref.watch(playerSessionProvider)` замість аргументів роуту
- [x] Роут-гард: якщо сесії немає — редірект на `/login`

### 2.3 Шар репозиторіїв

Розбити доступ до БД (`DatabaseHelper` лишається лише як утримувач з'єднання):

- [x] `AccountRepository` — login/register (обгортка над DatabaseHelper)
- [x] `ProfileRepository` — читання/оновлення профілю (fetchAccountWithProfile, applyDeltas, setFields)
- [x] заготовки: `InventoryRepository`, `CatalogRepository`, `TargetRepository` (наповнюються у кроках 03–06)

### 2.4 Типізовані аргументи роутів

- [x] Для екранів деталей (`target/detail`, `store/item`, …) — класи аргументів у `lib/utils/route_args.dart`
- [x] Прибрати `arguments: i` (int-індекси) — всі 10 wireframe-екранів оновлено
- [x] `GameScaffold` — прибрано параметр `AccountWithProfile?` (більше не передається через nav)

### 2.5 Тести

- [x] Unit: `PlayerSessionNotifier` — 5 тестів: initial/login-unknown/register/logout/updateProfileFields (з in-memory sqflite_ffi)
- [x] Widget: Home Page рендериться у `ProviderScope` без помилок

## Структура після кроку

```
lib/
  state/    player_session.dart
  repos/    account_repository.dart, profile_repository.dart,
            catalog_repository.dart, inventory_repository.dart,
            target_repository.dart (stub)
  utils/    route_args.dart, async_value_ext.dart
  db/       database_helper.dart (connection + migrations + static helpers)
```

## Критерії приймання

- [x] Жоден екран не читає `AccountWithProfile` з аргументів роуту
- [x] Покупка/зміна профілю (debug-кнопка +100 XP у ProfileScreen) миттєво видна на Home Page
- [x] Тести кроку зелені

---

## Summary (виконано 2026-07-04)

### Riverpod 3.x setup

- `flutter_riverpod: ^3.3.2` додано до pubspec; `main.dart` обгорнуто в `ProviderScope`.
- Використано **Riverpod 3.x API**: `Notifier<T>` + `NotifierProvider` (не старий StateNotifier/StateNotifierProvider з Riverpod 1.x).
- Додано extension `AsyncValueX.valueOrNull` (`lib/utils/async_value_ext.dart`), оскільки цей геттер відсутній у Riverpod 3.x AsyncValue.

### PlayerSessionNotifier

- Зберігає `AsyncValue<AccountWithProfile?>`. Стан `null` = гість, `AsyncData(awp)` = авторизований.
- Методи: `login` (повертає bool), `register`, `logout`, `refresh` (re-fetch з DB), `updateProfileFields(Map<String,int>)`.
- Репозиторії читаються через `ref.read` всередині методів (lazy-доступ без циклічних залежностей).

### Репозиторії

| Файл | Стан | Призначення |
|---|---|---|
| `account_repository.dart` | Робочий | login/register (делегує в DatabaseHelper) |
| `profile_repository.dart` | Робочий | fetchAccountWithProfile, applyDeltas, setFields |
| `catalog_repository.dart` | Stub | Наповниться у кроці 04 |
| `inventory_repository.dart` | Stub | Наповниться у кроці 05 |
| `target_repository.dart` | Stub | Наповниться у кроці 06 |

`DatabaseHelper` став "лише connection + migrations + static helpers": `joinedSelect` (const) та `rowToAccountWithProfile` (static) зроблені публічними для використання репозиторіями без дублювання SQL.

### Типізовані аргументи роутів

Файл `lib/utils/route_args.dart` містить: `TargetDetailArgs`, `StoreItemArgs`, `MarketItemArgs`, `WorkshopItemArgs`, `NewsItemArgs`, `AttackPrepArgs`. Всі 10 wireframe-екранів оновлено.

### Міграція екранів

- `LoginScreen` → `ConsumerStatefulWidget`: пише в `playerSessionProvider.notifier`, переходить на homePage **без аргументів**.
- `HomePageScreen` → `ConsumerWidget`: читає `ref.watch(playerSessionProvider)`, route guard при null.
- `ProfileScreen` → `ConsumerWidget`: читає сесію з провайдера; debug-кнопка `+100 XP` демонструє live state update.
- `GameScaffold`: прибрано `AccountWithProfile?` параметр; кнопка Home переходить без аргументів.

### Верифікація

- `flutter analyze` — **0 issues**
- `flutter test` — **10/10 passed** (4 password + 1 widget + 5 session tests)
  - `1. initial state is data(null)` ✅
  - `2. login unknown pseudo → false, stays null` ✅
  - `3. register → session populated` ✅
  - `4. logout → session null` ✅
  - `5. updateProfileFields → experience increments + refresh` ✅

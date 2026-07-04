# Крок 05 — Економічні екрани на реальних даних

**Статус: ✅ виконано** · Залежить від: 03, 04

## Мета

Store (6.1/6.2), Market (8.1/8.2) і Workshop (9.1/9.2) працюють із БД: покупка списує epts, предмет з'являється в інвентарі, апгрейд підвищує рівень предмета. Хардкод-списки видалено.

## Задачі

### 5.1 InventoryRepository + сервіс покупки

- [ ] `InventoryRepository`: `userSoftware(profileId)`, `userHardware(profileId)`, `addSoftware/addHardware`, `upgradeItem`
- [ ] `PurchaseService.buy(item)` — **одна транзакція**: перевірка балансу і req_level/req_black_trust → INSERT у інвентар → UPDATE балансу → refresh сесії. Помилки: `InsufficientFunds`, `RequirementsNotMet`, `AlreadyOwned`
- [ ] `UpgradeService.upgrade(userItem)`: вартість із `level_up_strategy` предмета, перевірка max_level, застосування приростів статів
- [ ] Перерахунок `profile.software_power` / `hardware_power` після кожної зміни інвентарю (сума статів)

### 5.2 Store — Screen 6.1 / 6.2

- [ ] Список із `CatalogRepository.storeItems()`: назва, тип, ціна, req_level; недоступні — задимлені з причиною
- [ ] Айтем-екран: стати (attack, penetration, trace, sockets), опис, кнопка BUY зі станами (куплено / бракує epts / низький рівень)
- [ ] Баланс epts видно у шапці (через GameScaffold або окремий віджет)

### 5.3 Market — Screen 8.1 / 8.2

- [ ] Аналогічно Store, але hardware: compute_power, power_draw, hw_type
- [ ] Фільтр-чіпи за hw_type (CPU/RAM/NET/GPU/IO)

### 5.4 Workshop — Screen 9.1 / 9.2

- [ ] Список = інвентар гравця (дві секції: SOFTWARE / HARDWARE), рівень предмета «Lv 2/5»
- [ ] Айтем-екран: поточні стати → стати після апгрейду (дельта зеленим), ціна апгрейду, кнопка UPGRADE
- [ ] На max_level — стан «MAXED»

### 5.5 Тести

- [ ] Unit: PurchaseService — успіх, брак коштів, дубль покупки, атомарність (баланс не списується при фейлі INSERT)
- [ ] Unit: UpgradeService — прирости за level_up_strategy, стеля max_level
- [ ] Widget: Store рендерить каталог; кнопка BUY блокується без коштів

## Критерії приймання

- Наскрізний сценарій: реєстрація → купити софт → побачити його в Workshop → апгрейднути → баланс і software_power оновилися скрізь (Home Page, Profile)
- Жодного `static const _items` в економічних екранах

# General map for Icon resolve:

> Це «сира» мапа асетів від власника. Робочий довідник розробника (реєстр
> `icon_key`, fallback-ланцюжок, правила додавання) —
> [docs/design/icon_presets.md](../design/icon_presets.md).

**Легенда статусів** (звірено з диском і бандлом білда, 2026-07-18):
✅ файл є і підключений у код · 🟡 файл є, у код не підключений · 🔴 файлу немає

| Icon           | Path                         | Element                        | Стан |
| -------------- | ---------------------------- | ------------------------------ | ---- |
| Back_arrow.png | assets\images\Back_arrow.png | Button back on each creen      | ✅ `GameScaffold` |
| Setting.png    | assets\images\Setting.png    | Button setting in gmae screens | ✅ `GameScaffold` |
| Info.png       | assets\images\icons\Info.png | Info affordance                | 🟡 місце в UI не призначене |

**Main Screen & Auth screen**

| Icon                       | Path                                            | Element               | Стан |
| -------------------------- | ----------------------------------------------- | --------------------- | ---- |
| hacker_green.png           | assets\images\hacker\hacker_green.png           | Sprite on main screen | 🟡 чекає на макет |
| hacker_green_anonimoys.png | assets\images\hacker\hacker_green_anonimoys.png | Sprite on auth screen | 🟡 чекає на макет |

**Home Page**

| Icon             | Path                           | Element                                 | Стан |
| ---------------- | ------------------------------ | --------------------------------------- | ---- |
| Darknet.png      | assets\images\Darknet.png      | Icon for software store                 | ✅ хаб |
| Spider_store.png | assets\images\Spider_store.png | Icon for hardware store                 | ✅ хаб |
| Workshop.png     | assets\images\Workshop.png     | Icon for workshop page                  | ✅ хаб |
| News.png         | assets\images\News.png         | Icon for news page                      | ✅ хаб |
| Targets_list.png | assets\images\Targets_list.png | Background for target bord on home page | 🟡 чекає на макет |
| Target.png       | assets\images\Target.png       | Background for target item on board     | 🟡 чекає на макет |
| Profile          | —                              | Icon for profile page                   | 🔴 файлу немає, треба домалювати |

**Каталожні іконки предметів** (`assets/images/ui/icons/`) — 🔴 тека порожня.
Пайплайн `icon_key` готовий і чекає на 21 файл; поки що всюди fallback-гліфи.
Перелік потрібних ключів — у [icon_presets.md](../design/icon_presets.md), розділ 3.

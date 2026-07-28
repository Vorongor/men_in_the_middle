**Music Map**

**Легенда статусів** (звірено з кодом після кроку 07, 2026-07-18):
✅ файл є і підключений у код · 🟡 файл є, у код не підключений · 🔴 файлу немає

Усі аудіофайли потрапляють у білд (під-теки декларовані в pubspec із кроку 06)
і **всі підключені в код** (крок 07). Технічні деталі — [media_presets.md](../design/media_presets.md).

| Track              | Path                                              | Playtime                                 | Стан |
| ------------------ | ------------------------------------------------- | ---------------------------------------- | ---- |
| main_theme.mp3     | assets\audio\main_theme.mp3                       | background music on main and auth screen | ✅ `playMenuTheme()` |
| 01_ingame_back.mp3 | assets\audio\background_tracks\01_ingame_back.mp3 | In game background music                 | ✅ плейлист хаба |
| 02_ingame_back.mp3 | assets\audio\background_tracks\02_ingame_back.mp3 | In game background music                 | ✅ плейлист хаба |
| 03_ingame_back.mp3 | assets\audio\background_tracks\03_ingame_back.mp3 | In game background music                 | ✅ плейлист хаба |
| 04_ingame_back.mp3 | assets\audio\background_tracks\04_ingame_back.mp3 | In game background music                 | ✅ плейлист хаба |
| 05_ingame_back.mp3 | assets\audio\background_tracks\05_ingame_back.mp3 | In game background music                 | ✅ плейлист хаба |
| 06_ingame_back.mp3 | assets\audio\background_tracks\06_ingame_back.mp3 | In game background music                 | ✅ плейлист хаба |
| 07_ingame_back.mp3 | assets\audio\background_tracks\07_ingame_back.mp3 | In game background music                 | ✅ плейлист хаба |
| 08_ingame_back.mp3 | assets\audio\background_tracks\08_ingame_back.mp3 | In game background music                 | ✅ плейлист хаба |
| ~~09_ingame_back~~ | —                                                 | —                                        | 🗑️ **видалено** |
| 10_ingame_back.mp3 | assets\audio\background_tracks\10_ingame_back.mp3 | In game background music                 | ✅ плейлист хаба |

> 🗑️ `09_ingame_back.mp3` **видалено на кроці 07**: був побайтовою копією `01`
> (той самий MD5, обидва 5976 КБ), тобто ~5.8 МБ дубля у вазі білда.
> Плейлист хаба — **9 унікальних треків**, shuffle без повтору підряд.

**Sound effects map**

| Sound             | Path                                         | Action                                          | Стан |
| ----------------- | -------------------------------------------- | ----------------------------------------------- | ---- |
| mouse-click.mp3   | assets\audio\sound_effects\mouse-click.mp3   | On any click common action (by/shoose/back/etc) | ✅ `AudioRouteObserver` |
| message_sound.mp3 | assets\audio\sound_effects\message_sound.mp3 | User level-up                                   | ✅ |
| keyboard.mp3      | assets\audio\sound_effects\keyboard.mp3      | Lopped during attack                            | ✅ луп на окремому плеєрі |
| button.mp3        | assets\audio\sound_effects\button.mp3        | On attack start button                          | ✅ LAUNCH ATTACK |
| light-switch.mp3  | assets\audio\sound_effects\light-switch.mp3  | Перемикачі в Settings + прев'ю гучності         | ✅ призначено на кроці 07 |

**Клип ділять кілька хуків** — клипів 5, хуків більше. Мапінг зібрано в
`AppAudio` (секція «Semantic aliases»), не по call-site'ах:

| Хук коду                     | Який клип грає      |
| ---------------------------- | ------------------- |
| міні-гра: catch              | `mouse-click`       |
| міні-гра: hit / lose         | `button`            |
| міні-гра: win                | `message_sound`     |
| покупка предмета             | `mouse-click`       |
| апгрейд предмета             | `message_sound`     |
| level-up                     | `message_sound`     |

> 📋 **У беклог і в анкету плейтесту (крок 09):** міні-гра не має власних
> catch/hit/win/lose, покупка й апгрейд ділять клипи з іншими діями. Якщо тестери
> скажуть, що звук одноманітний — доукомплектувати пак.

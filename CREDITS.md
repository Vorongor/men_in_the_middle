# Third-Party Assets and Credits

This document lists all third-party resources, assets, and software used in **The MiddleMen**, along with their licenses and attributions.

> ## ⚠️ Статус медіа: тимчасовий (alpha/beta)
>
> Уся музика, звук і графіка в цій збірці — **плейсхолдери для внутрішнього
> використання на стадіях альфи й бети**. Перед продакшином усі медіа-компоненти
> будуть перезібрані.
>
> Практичні наслідки:
> * не вкладатися в тонке доопрацювання цих активів (нормалізація рівнів,
>   ре-мастеринг, 2x/3x щільності іконок) — воно піде в кошик разом із ними;
> * рішення щодо бітрейту аудіо (крок 07) варто оцінювати як **тимчасовий**
>   компроміс заради ваги тестового APK, а не як фінальну якість звуку;
> * при заміні кожного активу — оновити цей файл і
>   `docs/design/media_presets.md`.
>
> Ліцензійно поточний набір чистий і для зовнішньої роздачі тестерам (крок 09):
> ліцензія Pixabay дозволяє комерційне використання, графіка — власна.
> Тобто «внутрішнє використання» тут — рішення про якість і тимчасовість,
> а не ліцензійне обмеження.

## Fonts

### Geist Mono / Geist Pixel
*   **Asset:** `assets/fonts/GeistPixel-Regular-VariableFont_ELSH.ttf`
*   **License:** SIL Open Font License (OFL) version 1.1
*   **Description:** Variable pixel-based monospace typeface used for display headers, HUD stat readouts, and callouts.
*   **License file:** shipped alongside the font in `assets/fonts/`.

### Share Tech Mono
*   **Source:** Google Fonts, loaded at runtime via the `google_fonts` package.
*   **License:** SIL Open Font License (OFL) version 1.1
*   **Description:** Body text, data readouts and captions.

## Graphics

**All artwork in this project is original**, drawn in-house by the project's own
designer. It is **not** third-party content: copyright rests with the project, and
no external attribution or license obligation applies to any of it.

### UI / navigation artwork
*   **Assets:** `assets/images/Back_arrow.png`, `Setting.png`, `Darknet.png`,
    `Spider_store.png`, `Workshop.png`, `News.png`, `Targets_list.png`, `Target.png`,
    `assets/images/hacker/*.png`, `assets/images/icons/Info.png`,
    `assets/images/backgrounds/*`
*   **Source:** original work by the project designer.
*   **License:** proprietary — all rights reserved by the project.

### App icon and splash
*   **Assets:** `assets/branding/app_icon.png`, `app_icon_foreground.png`, `splash_logo.png`
*   **Source:** derived from the designer's `assets/images/hacker/hacker_green.png`
    (composited onto the `#0A0A0C` palette background and rescaled for the launcher
    masks — see `docs/design/media_presets.md`). Same ownership as the source art.

## Audio

All music and sound effects were downloaded from **Pixabay**
(<https://pixabay.com/music/> and <https://pixabay.com/sound-effects/>) and are used
under the **Pixabay Content License**.

That license permits free commercial and non-commercial use without attribution.
Two of its restrictions are worth keeping in mind for this project:

*   Pixabay content may not be redistributed **as-is on a standalone basis** — i.e.
    the tracks may ship inside the game, but must not be offered as a downloadable
    music pack. Current usage is compliant.
*   It may not be used in a way that is defamatory or that portrays identifiable
    people or brands negatively. Not applicable here.

### Background music
*   **Assets:** `assets/audio/main_theme.mp3`,
    `assets/audio/background_tracks/*.mp3` (9 tracks)
*   **Source:** Pixabay — <https://pixabay.com/music/>
*   **License:** Pixabay Content License (no attribution required)

### Sound effects
*   **Assets:** `assets/audio/sound_effects/mouse-click.mp3`, `button.mp3`,
    `message_sound.mp3`, `keyboard.mp3`, `light-switch.mp3`
*   **Source:** Pixabay — <https://pixabay.com/sound-effects/>
*   **License:** Pixabay Content License (no attribution required)

> 📋 **Незаписане:** конкретні URL і автори окремих треків/клипів не зафіксовані.
> Ліцензія Pixabay атрибуції не вимагає, тож формально це не порушення — але без
> посилань неможливо довести походження, якщо колись виникне суперечка, і
> неможливо знайти автора, щоб подякувати чи докупити щось у тому ж стилі.
> Якщо історія завантажень збереглася — варто дописати URL до кожного файлу.

> **Ліцензійна гігієна** — принцип Alpha 2.0: кожен сторонній актив фіксується тут
> із джерелом і ліцензією. Станом на 2026-07-18 усі активи покриті.

## Software

*   **Flutter / Flame / Riverpod / sqflite / media_kit** — see `pubspec.yaml` for
    versions; all BSD-3-Clause or MIT.

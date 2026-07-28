class AppStrings {
  static const gameTitle = 'The MiddleMen';
}

/// Single registry of bundled image assets — see docs/design/icon_presets.md.
/// Nothing outside this class should hard-code an `assets/images/...` path.
class AppImages {
  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const homeBg = 'assets/images/backgrounds/home-bg-techno.jpg';
  static const loginBg = 'assets/images/backgrounds/login.jpg';

  // ── Chrome (present on most screens) ──────────────────────────────────────
  static const backArrow = 'assets/images/Back_arrow.png';
  static const settings = 'assets/images/Setting.png';

  // ── Hub navigation (Screen 3) ─────────────────────────────────────────────
  static const navStore = 'assets/images/Darknet.png';
  static const navMarket = 'assets/images/Spider_store.png';
  static const navWorkshop = 'assets/images/Workshop.png';
  static const navNews = 'assets/images/News.png';

  // ── Target board ──────────────────────────────────────────────────────────
  static const targetBoardBg = 'assets/images/Targets_list.png';
  static const targetItemBg = 'assets/images/Target.png';

  // ── Character sprites ─────────────────────────────────────────────────────
  static const hackerGreen = 'assets/images/hacker/hacker_green.png';
  static const hackerAnon = 'assets/images/hacker/hacker_green_anonimoys.png';

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const info = 'assets/images/icons/Info.png';

  /// Folder holding catalog item icons resolved by `icon_key`.
  /// A key `foo` maps to `${catalogIconDir}foo.png`.
  static const catalogIconDir = 'assets/images/ui/icons/';

  /// Resolves a catalog `icon_key` to its asset path.
  static String catalogIcon(String iconKey) => '$catalogIconDir$iconKey.png';
}

/// Audio asset names, relative to `assets/audio/` (FlameAudio's prefix).
///
/// Every constant here points at a file that actually ships — see
/// docs/planning/sounds_and_music_map.md. Before step 07 these named
/// `sfx_*.mp3` clips that were never in the repo, so every playSfx() call
/// silently no-opped.
class AppAudio {
  // ── Music ─────────────────────────────────────────────────────────────────
  /// Menu and auth screens.
  static const mainTheme = 'main_theme.mp3';

  /// In-game hub playlist. Nine unique tracks — the former `09_ingame_back`
  /// was a byte-identical copy of `01` and was dropped in step 07.
  static const hubPlaylist = <String>[
    'background_tracks/01_ingame_back.mp3',
    'background_tracks/02_ingame_back.mp3',
    'background_tracks/03_ingame_back.mp3',
    'background_tracks/04_ingame_back.mp3',
    'background_tracks/05_ingame_back.mp3',
    'background_tracks/06_ingame_back.mp3',
    'background_tracks/07_ingame_back.mp3',
    'background_tracks/08_ingame_back.mp3',
    'background_tracks/10_ingame_back.mp3',
  ];

  // ── Sound effects (the five clips in sound_effects/) ──────────────────────
  /// Generic click: navigation, selection, back.
  static const sfxClick = 'sound_effects/mouse-click.mp3';

  /// Heavier confirm: LAUNCH ATTACK and minigame start.
  static const sfxButton = 'sound_effects/button.mp3';

  /// Notification chime — used for level-up.
  static const sfxMessage = 'sound_effects/message_sound.mp3';

  /// Typing loop, played continuously for the duration of an attack.
  static const sfxKeyboardLoop = 'sound_effects/keyboard.mp3';

  /// Toggle flick — Settings switches and sliders.
  static const sfxToggle = 'sound_effects/light-switch.mp3';

  // ── Semantic aliases ──────────────────────────────────────────────────────
  // The clip pack is smaller than the set of hooks the code already has, so
  // several hooks intentionally share a clip. Recorded here rather than at the
  // call sites so the sharing is visible in one place, and so swapping in a
  // dedicated clip later is a one-line change.
  //
  // Gaps flagged for the step 09 playtest questionnaire: the minigame has no
  // distinct catch/hit/win/lose sounds, and purchase/upgrade share the click.
  static const sfxCatch = sfxClick;
  static const sfxHit = sfxButton;
  static const sfxWin = sfxMessage;
  static const sfxLose = sfxButton;
  static const sfxPurchase = sfxClick;
  static const sfxUpgrade = sfxMessage;
  static const sfxLevelUp = sfxMessage;
}

class AppErrors {
  static const wrongCredentials = 'CODE-400, WRONG CREDENTIALS!';
  static const dbFail = 'CODE-500, DB FAIL!';
}

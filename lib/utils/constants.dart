class AppStrings {
  static const gameTitle = 'The MiddleMen';
}

class AppImages {
  static const homeBg = 'assets/images/backgrounds/home-bg-techno.jpg';
  static const loginBg = 'assets/images/backgrounds/login.jpg';
}

class AppAudio {
  static const mainTheme = 'main_theme.mp3';

  // Sniffer minigame SFX. No clips are bundled yet (assets/audio/ only ships
  // mainTheme) — AudioService.playSfx() no-ops safely until an audio pass
  // adds these files.
  static const sfxCatch = 'sfx_catch.mp3';
  static const sfxHit = 'sfx_hit.mp3';
  static const sfxWin = 'sfx_win.mp3';
  static const sfxLose = 'sfx_lose.mp3';

  // Economy/progression SFX — same "no clips yet" situation as above.
  static const sfxPurchase = 'sfx_purchase.mp3';
  static const sfxUpgrade = 'sfx_upgrade.mp3';
  static const sfxLevelUp = 'sfx_level_up.mp3';
}

class AppErrors {
  static const wrongCredentials = 'CODE-400, WRONG CREDENTIALS!';
  static const dbFail = 'CODE-500, DB FAIL!';
}

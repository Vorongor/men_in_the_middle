import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._();
  SettingsService._();

  static const _kMuteAll = 'mute_all';
  static const _kGeneralVol = 'general_volume';
  static const _kMusicVol = 'music_volume';
  static const _kEffectsVol = 'effects_volume';

  bool muteAll = false;
  double generalVolume = 1.0;
  double musicVolume = 1.0;
  double effectsVolume = 1.0;

  double get effectiveMusicVolume =>
      muteAll ? 0.0 : (generalVolume * musicVolume);

  double get effectiveEffectsVolume =>
      muteAll ? 0.0 : (generalVolume * effectsVolume);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    muteAll = prefs.getBool(_kMuteAll) ?? false;
    generalVolume = prefs.getDouble(_kGeneralVol) ?? 1.0;
    musicVolume = prefs.getDouble(_kMusicVol) ?? 1.0;
    effectsVolume = prefs.getDouble(_kEffectsVol) ?? 1.0;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMuteAll, muteAll);
    await prefs.setDouble(_kGeneralVol, generalVolume);
    await prefs.setDouble(_kMusicVol, musicVolume);
    await prefs.setDouble(_kEffectsVol, effectsVolume);
  }
}

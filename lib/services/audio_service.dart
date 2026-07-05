import 'dart:io';
import 'package:flame_audio/flame_audio.dart';

import '../utils/app_logger.dart';
import '../utils/constants.dart';
import 'settings_service.dart';

class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._();

  static final _log = AppLogger.of('AudioService');

  bool _playing = false;

  Future<void> startBgm() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (_playing) return;
    await FlameAudio.bgm.initialize();
    await FlameAudio.bgm.play(
      AppAudio.mainTheme,
      volume: SettingsService.instance.effectiveMusicVolume,
    );
    _playing = true;
  }

  Future<void> stopBgm() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (!_playing) return;
    await FlameAudio.bgm.stop();
    _playing = false;
  }

  Future<void> applyVolume() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (!_playing) return;
    await FlameAudio.bgm.audioPlayer
        .setVolume(SettingsService.instance.effectiveMusicVolume);
  }

  /// Plays a one-shot sound effect, respecting the effects volume slider.
  ///
  /// Swallows failures: this project doesn't ship real SFX asset files yet
  /// (only `main_theme.mp3` exists under assets/audio/), so a missing file
  /// must not crash gameplay — it's a silent no-op until an audio pass adds
  /// the actual clips referenced by [AppAudio].
  Future<void> playSfx(String fileName) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    final volume = SettingsService.instance.effectiveEffectsVolume;
    if (volume <= 0) return;
    try {
      await FlameAudio.play(fileName, volume: volume);
    } catch (e) {
      _log.warning('playSfx($fileName) failed', e);
    }
  }
}

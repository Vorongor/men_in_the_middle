import 'package:flame_audio/flame_audio.dart';
import '../utils/constants.dart';
import 'settings_service.dart';

class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._();

  bool _playing = false;

  Future<void> startBgm() async {
    if (_playing) return;
    FlameAudio.bgm.initialize();
    await FlameAudio.bgm.play(
      AppAudio.mainTheme,
      volume: SettingsService.instance.effectiveMusicVolume,
    );
    _playing = true;
  }

  Future<void> stopBgm() async {
    if (!_playing) return;
    await FlameAudio.bgm.stop();
    _playing = false;
  }

  Future<void> applyVolume() async {
    if (!_playing) return;
    await FlameAudio.bgm.audioPlayer
        .setVolume(SettingsService.instance.effectiveMusicVolume);
  }
}

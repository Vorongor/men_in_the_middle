import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../utils/app_logger.dart';
import '../utils/constants.dart';
import 'settings_service.dart';

/// Which background music context is currently active.
enum BgmMode {
  none,

  /// Menu and auth — the single [AppAudio.mainTheme], looped.
  menu,

  /// In-game hub — the shuffled [AppAudio.hubPlaylist].
  hub,
}

class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._();

  static final _log = AppLogger.of('AudioService');

  final _rng = Random();

  BgmMode _mode = BgmMode.none;
  BgmMode get mode => _mode;

  /// Shuffled playlist and cursor, only meaningful in [BgmMode.hub].
  List<String> _queue = const [];
  int _cursor = 0;

  /// Fires when a hub track finishes so the next one can start. The menu theme
  /// loops natively and does not need this.
  StreamSubscription<void>? _trackCompleteSub;

  /// Dedicated player for looping SFX. It has to be separate from
  /// `FlameAudio.bgm`, otherwise starting the keyboard loop would evict the
  /// music — they play simultaneously by design.
  AudioPlayer? _loopPlayer;

  bool get _inTest => Platform.environment.containsKey('FLUTTER_TEST');

  // ── Background music ───────────────────────────────────────────────────────

  /// Menu/auth theme. Kept as the historical entry point called from main().
  Future<void> startBgm() => playMenuTheme();

  Future<void> playMenuTheme() async {
    if (_inTest) return;
    if (_mode == BgmMode.menu) return;

    await _cancelPlaylist();
    _mode = BgmMode.menu;
    try {
      await FlameAudio.bgm.initialize();
      await FlameAudio.bgm.play(
        AppAudio.mainTheme,
        volume: SettingsService.instance.effectiveMusicVolume,
      );
    } catch (e) {
      _log.warning('playMenuTheme failed', e);
      _mode = BgmMode.none;
    }
  }

  /// Starts the in-game playlist. Repeated calls while already in hub mode are
  /// ignored, so navigating between hub screens doesn't restart the music.
  Future<void> playHubPlaylist() async {
    if (_inTest) return;
    if (_mode == BgmMode.hub) return;

    await _cancelPlaylist();
    _mode = BgmMode.hub;
    _queue = _shuffledQueue(avoidFirst: _queue.isEmpty ? null : _queue.last);
    _cursor = 0;

    try {
      await FlameAudio.bgm.initialize();
      // Bgm.play() hard-codes ReleaseMode.loop, which would keep one track
      // spinning forever and never fire onPlayerComplete. Flip it back to
      // release so completion advances the playlist.
      _trackCompleteSub = FlameAudio.bgm.audioPlayer.onPlayerComplete.listen(
        (_) => unawaited(_advance()),
      );
      await _playCurrent();
    } catch (e) {
      _log.warning('playHubPlaylist failed', e);
      _mode = BgmMode.none;
    }
  }

  Future<void> _playCurrent() async {
    await FlameAudio.bgm.play(
      _queue[_cursor],
      volume: SettingsService.instance.effectiveMusicVolume,
    );
    await FlameAudio.bgm.audioPlayer.setReleaseMode(ReleaseMode.release);
  }

  Future<void> _advance() async {
    if (_mode != BgmMode.hub || _queue.isEmpty) return;
    _cursor++;
    if (_cursor >= _queue.length) {
      // Reshuffle for the next lap, avoiding an immediate repeat across the
      // seam so the same track can't play twice in a row.
      _queue = _shuffledQueue(avoidFirst: _queue.last);
      _cursor = 0;
    }
    try {
      await _playCurrent();
    } catch (e) {
      _log.warning('playlist advance failed', e);
    }
  }

  /// Shuffles the playlist, guaranteeing the first entry differs from
  /// [avoidFirst] (the track that just played).
  @visibleForTesting
  List<String> shuffledQueue({String? avoidFirst}) => _shuffledQueue(
    avoidFirst: avoidFirst,
  );

  List<String> _shuffledQueue({String? avoidFirst}) {
    final list = [...AppAudio.hubPlaylist]..shuffle(_rng);
    if (avoidFirst != null && list.length > 1 && list.first == avoidFirst) {
      list.add(list.removeAt(0));
    }
    return list;
  }

  Future<void> _cancelPlaylist() async {
    await _trackCompleteSub?.cancel();
    _trackCompleteSub = null;
  }

  Future<void> stopBgm() async {
    if (_inTest) return;
    if (_mode == BgmMode.none) return;
    await _cancelPlaylist();
    _mode = BgmMode.none;
    try {
      await FlameAudio.bgm.stop();
    } catch (e) {
      _log.warning('stopBgm failed', e);
    }
  }

  /// Re-applies the volume sliders to everything currently audible — music and
  /// any running SFX loop. Called by the settings screen on every change.
  Future<void> applyVolume() async {
    if (_inTest) return;
    final settings = SettingsService.instance;
    try {
      if (_mode != BgmMode.none) {
        await FlameAudio.bgm.audioPlayer.setVolume(settings.effectiveMusicVolume);
      }
      await _loopPlayer?.setVolume(settings.effectiveEffectsVolume);
    } catch (e) {
      _log.warning('applyVolume failed', e);
    }
  }

  // ── Sound effects ──────────────────────────────────────────────────────────

  /// Plays a one-shot sound effect, respecting the effects volume slider.
  ///
  /// Failures are swallowed rather than propagated: a missing or unplayable
  /// clip must never interrupt gameplay.
  Future<void> playSfx(String fileName) async {
    if (_inTest) return;
    final volume = SettingsService.instance.effectiveEffectsVolume;
    if (volume <= 0) return;
    try {
      await FlameAudio.play(fileName, volume: volume);
    } catch (e) {
      _log.warning('playSfx($fileName) failed', e);
    }
  }

  /// Starts a continuously looping effect (the keyboard track during an
  /// attack). Calling it while a loop already runs replaces it.
  ///
  /// Unlike [playSfx] this ignores a zero volume rather than bailing out: the
  /// loop is started muted so that raising the slider mid-attack takes effect
  /// via [applyVolume] instead of leaving silence until the next attack.
  Future<void> startLoopSfx(String fileName) async {
    if (_inTest) return;
    await stopLoopSfx();
    try {
      _loopPlayer = await FlameAudio.loop(
        fileName,
        volume: SettingsService.instance.effectiveEffectsVolume,
      );
    } catch (e) {
      _log.warning('startLoopSfx($fileName) failed', e);
      _loopPlayer = null;
    }
  }

  Future<void> stopLoopSfx() async {
    if (_inTest) return;
    final player = _loopPlayer;
    if (player == null) return;
    _loopPlayer = null;
    try {
      await player.stop();
      await player.dispose();
    } catch (e) {
      _log.warning('stopLoopSfx failed', e);
    }
  }

  /// Pauses/resumes the SFX loop alongside the minigame's own pause, so an
  /// paused attack doesn't keep typing in the background.
  Future<void> setLoopPaused(bool paused) async {
    if (_inTest) return;
    final player = _loopPlayer;
    if (player == null) return;
    try {
      await (paused ? player.pause() : player.resume());
    } catch (e) {
      _log.warning('setLoopPaused($paused) failed', e);
    }
  }
}

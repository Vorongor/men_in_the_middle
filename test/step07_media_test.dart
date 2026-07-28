import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/services/audio_service.dart';
import 'package:men_in_the_middle/utils/constants.dart';

void main() {
  group('1. Audio asset wiring', () {
    /// Before step 07 every AppAudio constant named a file that was never in
    /// the repo, so all twelve playSfx() calls silently no-opped and nobody
    /// noticed. This test is the guard against that regressing.
    test('every AppAudio constant points at a file that exists', () {
      const clips = {
        'mainTheme': AppAudio.mainTheme,
        'sfxClick': AppAudio.sfxClick,
        'sfxButton': AppAudio.sfxButton,
        'sfxMessage': AppAudio.sfxMessage,
        'sfxKeyboardLoop': AppAudio.sfxKeyboardLoop,
        'sfxToggle': AppAudio.sfxToggle,
      };

      final missing = <String>[];
      clips.forEach((name, path) {
        if (!File('assets/audio/$path').existsSync()) {
          missing.add('AppAudio.$name → assets/audio/$path');
        }
      });

      expect(missing, isEmpty, reason: 'Missing audio clips:\n${missing.join('\n')}');
    });

    test('every hub playlist track exists', () {
      final missing = AppAudio.hubPlaylist
          .where((t) => !File('assets/audio/$t').existsSync())
          .toList();

      expect(missing, isEmpty, reason: 'Missing tracks: $missing');
    });

    test('hub playlist has no duplicate entries', () {
      // 09_ingame_back.mp3 was a byte-identical copy of 01 and was removed in
      // step 07; this keeps a duplicate from creeping back into the list.
      expect(AppAudio.hubPlaylist.toSet().length, AppAudio.hubPlaylist.length);
    });

    test('no audio file on disk is left unreferenced', () {
      // Acceptance criterion: every file under assets/audio/ is either wired
      // up or deliberately deleted — no dead weight in the build.
      final referenced = {
        AppAudio.mainTheme,
        AppAudio.sfxClick,
        AppAudio.sfxButton,
        AppAudio.sfxMessage,
        AppAudio.sfxKeyboardLoop,
        AppAudio.sfxToggle,
        ...AppAudio.hubPlaylist,
      };

      final onDisk = Directory('assets/audio')
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path
              .replaceAll(r'\', '/')
              .replaceFirst('assets/audio/', ''))
          .toList();

      final orphans = onDisk.where((f) => !referenced.contains(f)).toList();
      expect(orphans, isEmpty, reason: 'Unreferenced audio files: $orphans');
    });
  });

  group('2. Hub playlist shuffle', () {
    final audio = AudioService.instance;

    test('shuffle returns every track exactly once', () {
      for (var i = 0; i < 50; i++) {
        final queue = audio.shuffledQueue();
        expect(queue.toSet(), AppAudio.hubPlaylist.toSet());
        expect(queue.length, AppAudio.hubPlaylist.length);
      }
    });

    test('shuffle never opens with the track that just played', () {
      // Guards the seam between laps: without this, reshuffling could put the
      // same track back-to-back across the boundary.
      for (final previous in AppAudio.hubPlaylist) {
        for (var i = 0; i < 30; i++) {
          final queue = audio.shuffledQueue(avoidFirst: previous);
          expect(
            queue.first,
            isNot(previous),
            reason: 'Track $previous repeated across the lap boundary',
          );
        }
      }
    });
  });

  group('3. Branding assets', () {
    test('master art referenced by pubspec exists', () {
      // Scraped rather than YAML-parsed to avoid pulling in a `yaml` dependency
      // just for one assertion: every assets/branding/... path the branding
      // config names must resolve to a real file.
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final paths = RegExp(r'assets/branding/[\w\-.]+\.png')
          .allMatches(pubspec)
          .map((m) => m.group(0)!)
          .toSet();

      expect(paths, isNotEmpty, reason: 'branding config lost its image paths');

      for (final path in paths) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '$path is referenced by pubspec branding config but missing',
        );
      }
    });

    test('generated Android launcher icons are present', () {
      // flutter_launcher_icons writes into the native project; if someone
      // changes the master art without re-running it, this still passes — it
      // only catches the "never generated at all" case.
      final res = Directory('android/app/src/main/res');
      expect(res.existsSync(), isTrue);

      final launcherIcons = res
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.contains('ic_launcher'))
          .toList();

      expect(launcherIcons, isNotEmpty, reason: 'run: dart run flutter_launcher_icons');
    });
  });

  group('4. Sound map documentation', () {
    test('sounds_and_music_map.md lists no removed track', () {
      final map = File('docs/planning/sounds_and_music_map.md').readAsStringSync();
      // The doc may mention 09 in the note explaining its removal, but it must
      // not still be presented as a live playlist entry.
      expect(
        map.contains(r'background_tracks\09_ingame_back.mp3'),
        isFalse,
        reason: '09_ingame_back was deleted — the map must not list its path',
      );
    });
  });
}

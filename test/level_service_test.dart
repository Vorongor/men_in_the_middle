import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/services/level_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        if (message == null) return null;
        final key = utf8.decode(
          message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
        );
        if (key.contains('level_curve.json')) {
          final bytes = File('assets/data/catalog/level_curve.json').readAsBytesSync();
          return ByteData.sublistView(bytes);
        }
        return null;
      },
    );
  });

  group('LevelService.resolveLevel', () {
    // level_curve.json: level 1 -> 0, level 2 -> 100, level 3 -> 303, ... level 10 -> 3344.
    test('does not level up below the next threshold', () async {
      final level = await LevelService.resolveLevel(1, 99);
      expect(level, 1);
    });

    test('levels up exactly at the threshold', () async {
      final level = await LevelService.resolveLevel(1, 100);
      expect(level, 2);
    });

    test('jumps multiple levels in a single call when exp is far ahead', () async {
      final level = await LevelService.resolveLevel(1, 5000);
      expect(level, 10); // max seeded level, well past its threshold
    });

    test('never regresses below the current level even with 0 exp', () async {
      final level = await LevelService.resolveLevel(5, 0);
      expect(level, 5);
    });
  });

  group('LevelService.progressToNextLevel', () {
    test('0.0 right at the current level threshold', () async {
      final progress = await LevelService.progressToNextLevel(1, 0);
      expect(progress, 0.0);
    });

    test('0.5 halfway to the next level threshold', () async {
      // level 1 -> 0, level 2 -> 100: halfway is exp 50.
      final progress = await LevelService.progressToNextLevel(1, 50);
      expect(progress, closeTo(0.5, 1e-9));
    });

    test('1.0 once experience meets or exceeds the next threshold', () async {
      final progress = await LevelService.progressToNextLevel(1, 500);
      expect(progress, 1.0);
    });

    test('1.0 at the max seeded level (no higher threshold to progress toward)', () async {
      final progress = await LevelService.progressToNextLevel(10, 999999);
      expect(progress, 1.0);
    });
  });
}

import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:men_in_the_middle/state/player_session.dart';
import 'package:men_in_the_middle/utils/async_value_ext.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Generates a unique username for each test run to avoid UNIQUE constraint
/// failures when the persistent test DB is reused across runs.
String _uniquePseudo(String prefix) =>
    '${prefix}_${Random().nextInt(0x7FFFFFFF)}';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Provide a minimal legends.json matching the format expected by
    // pickRandomLegend(): {"hacker_legends": [{"legend": "..."}]}
    const legendsJson =
        '{"hacker_legends":[{"legend":"Test legend for unit tests."}]}';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (_) async => ByteData.sublistView(
        Uint8List.fromList(legendsJson.codeUnits),
      ),
    );
  });

  group('PlayerSessionNotifier', () {
    late ProviderContainer container;
    late PlayerSessionNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(playerSessionProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('1. initial state is data(null)', () {
      final state = container.read(playerSessionProvider);
      expect(state, isA<AsyncData<dynamic>>());
      expect(state.valueOrNull, isNull);
    });

    test('2. login unknown pseudo → false, stays null', () async {
      final ok = await notifier.login('ghost_xxxxxx', 'wrong_pass');
      expect(ok, isFalse);
      expect(container.read(playerSessionProvider).valueOrNull, isNull);
    });

    test('3. register → session populated', () async {
      final pseudo = _uniquePseudo('agent');
      await notifier.register(pseudo, 'secr3t!');
      final state = container.read(playerSessionProvider);
      expect(state.valueOrNull, isNotNull,
          reason: 'state after register: $state');
      expect(state.valueOrNull!.account.pseudo, pseudo);
    });

    test('4. logout → session null', () async {
      await notifier.register(_uniquePseudo('agent'), 'secr3t!');
      notifier.logout();
      expect(container.read(playerSessionProvider).valueOrNull, isNull);
    });

    test('5. updateProfileFields → experience increments', () async {
      await notifier.register(_uniquePseudo('delta'), 'p4ss!');
      final before = container.read(playerSessionProvider).valueOrNull;
      expect(before, isNotNull, reason: 'must be logged in first');
      expect(before!.profile.experience, 0);

      await notifier.updateProfileFields({'experience': 100});

      final after = container.read(playerSessionProvider).valueOrNull;
      expect(after, isNotNull);
      expect(after!.profile.experience, 100);
    });
  });
}

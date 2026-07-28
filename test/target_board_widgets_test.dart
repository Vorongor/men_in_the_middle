import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:men_in_the_middle/db/database_helper.dart';
import 'package:men_in_the_middle/screens/target_board_screen.dart';
import 'package:men_in_the_middle/state/player_session.dart';
import 'package:men_in_the_middle/utils/async_value_ext.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/async_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Disable network font fetching in tests
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(mockCatalogAssetBundle);

  group('Target Board Widget Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      dbHelper.dbName = 'middlemen_board_widgets_${Random().nextInt(0x7FFFFFFF)}.db';
    });

    tearDown(() async {
      await dbHelper.close();
    });

    testWidgets('TargetBoard renders contracts and calculates difficulty badges correctly', (
      tester,
    ) async {
      // Whole body inside runAsync(): real sqflite I/O deadlocks in the
      // FakeAsync zone a testWidgets body normally runs in. See step_08.
      await tester.runAsync(() async {
        // 1. Register and login player (initially softwarePower = 10)
        final pseudo = 'widget_board_agent_${Random().nextInt(0x7FFFFFFF)}';
        final awp = await dbHelper.register(pseudo, 'Password123!');
        final profileId = awp.profile.id!;

        final db = await dbHelper.db;

        // Ensure we have exactly 1 active contract with defense = 10 for deterministic testing
        await db.delete('active_contracts', where: 'profile_id = ?', whereArgs: [profileId]);
        await db.insert('active_contracts', {
          'profile_id': profileId,
          'target_template_id': 1, // Local Merchant PC
          'mission_type_id': 1, // Data Theft
          'defense': 10,
          'epts_reward': 50,
          'trust_reward': 5,
          'expires_at': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'is_completed': 0,
        });

        // 2. Setup Riverpod Scope
        final container = ProviderContainer();
        await container.read(playerSessionProvider.notifier).login(pseudo, 'Password123!');

        // Verify login state
        final session = container.read(playerSessionProvider).valueOrNull;
        expect(session, isNotNull);

        // 3. Pump TargetBoardScreen with player softwarePower = 10 (defense 10 vs power 10 -> MEDIUM)
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: TargetBoardScreen()),
          ),
        );

        await settleAsync(tester);

        // Verify list items
        // Target name renders as authored; only the mission line is
        // upper-cased. The old all-caps expectation predates the step 05
        // theme migration and was never caught, because this file was hanging.
        expect(find.text('Local Merchant PC'), findsOneWidget);
        expect(find.text('DATA THEFT  ·  BOUNTY: 50 EPTS'), findsOneWidget);
        expect(find.text('MEDIUM'), findsOneWidget);

        // 4. Update player softwarePower to 20 (defense 10 vs power 20 -> LOW)
        await db.update(
          'profiles',
          {'software_power': 20},
          where: 'id = ?',
          whereArgs: [profileId],
        );
        await container.read(playerSessionProvider.notifier).refresh();
        await tester.pump(); // Request rebuild

        // Invalidate activeContractsProvider to reload list
        container.invalidate(activeContractsProvider);
        await settleAsync(tester);

        expect(find.text('LOW'), findsOneWidget);

        // 5. Update player softwarePower to 5 (defense 10 vs power 5 -> HIGH)
        await db.update('profiles', {'software_power': 5}, where: 'id = ?', whereArgs: [profileId]);
        await container.read(playerSessionProvider.notifier).refresh();
        await tester.pump();

        container.invalidate(activeContractsProvider);
        await settleAsync(tester);

        expect(find.text('HIGH'), findsOneWidget);
      });
    });
  });
}

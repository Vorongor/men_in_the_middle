import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:men_in_the_middle/db/database_helper.dart';
import 'package:men_in_the_middle/screens/profile_screen.dart';
import 'package:men_in_the_middle/state/player_session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/async_widget_harness.dart';

// Test bodies run inside tester.runAsync() and settle via settleAsync():
// a testWidgets body executes in a FakeAsync zone whose clock never advances
// for real sqflite I/O, so awaiting the DB deadlocks the isolate. Root-caused
// in step 08 — see docs/planning/alpha_2_0/step_08_tests_ci_stabilization.md.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(mockCatalogAssetBundle);

  group('ProfileScreen', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      dbHelper.dbName = 'middlemen_profile_widget_${Random().nextInt(0x7FFFFFFF)}.db';
    });

    tearDown(() async {
      await dbHelper.close();
    });

    testWidgets('renders identity, capabilities, reputation and empty history for a fresh agent', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final pseudo = 'profile_agent_${Random().nextInt(0x7FFFFFFF)}';
        final awp = await dbHelper.register(pseudo, 'Password123!');

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(playerSessionProvider.notifier).login(pseudo, 'Password123!');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await settleAsync(tester);

        expect(find.text(pseudo), findsOneWidget);
        expect(find.textContaining('Mouse'), findsOneWidget);
        expect(find.text('${awp.profile.eptsBalance}'), findsOneWidget);
        // A fresh profile starts with both wanted and black-trust at zero, so
        // two meters render "0 / 100" — the old findsOneWidget was written
        // before the second meter existed.
        expect(find.text('0 / 100'), findsNWidgets(2));
        expect(find.text('No operations logged yet.'), findsOneWidget);
      });
    });

    testWidgets('shows a recent operation after one is logged', (tester) async {
      await tester.runAsync(() async {
        final pseudo = 'profile_history_${Random().nextInt(0x7FFFFFFF)}';
        final awp = await dbHelper.register(pseudo, 'Password123!');
        final profileId = awp.profile.id!;

        final db = await dbHelper.db;
        await db.insert('attack_log', {
          'profile_id': profileId,
          'target_template_id': 1,
          'mission_type_id': 1,
          'result': 'success',
          'epts_delta': 80,
          'wanted_delta': -1,
          'trust_delta': 2,
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(playerSessionProvider.notifier).login(pseudo, 'Password123!');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await settleAsync(tester);

        expect(find.textContaining('Local Merchant PC'), findsOneWidget);
        expect(find.text('+80 EPTS'), findsOneWidget);
      });
    });
  });
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:men_in_the_middle/db/database_helper.dart';
import 'package:men_in_the_middle/repos/catalog_repository.dart';
import 'package:men_in_the_middle/screens/store_item_screen.dart';
import 'package:men_in_the_middle/screens/store_screen.dart';
import 'package:men_in_the_middle/state/player_session.dart';
import 'package:men_in_the_middle/utils/route_args.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/async_widget_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Disable network google font lookups in tests
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(mockCatalogAssetBundle);

  group('Economy Widgets Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      dbHelper.dbName = 'middlemen_widgets_test_${Random().nextInt(0x7FFFFFFF)}.db';
    });

    tearDown(() async {
      await dbHelper.close();
    });

    testWidgets('StoreScreen and StoreItemScreen interaction flow', (tester) async {
      // The whole body runs inside tester.runAsync(): a testWidgets body
      // normally executes in a FakeAsync zone whose clock never advances for
      // real I/O, so awaiting sqflite deadlocks the isolate outright — no
      // timeout fires, the run just hangs. See step_08 Summary for the
      // diagnosis. pumpAndSettle() is likewise replaced by bounded pumps with
      // real delays, since settling is unreliable outside FakeAsync.
      await tester.runAsync(() async {
        // 1. Register and login player
        final pseudo = 'widget_eco_agent_${Random().nextInt(0x7FFFFFFF)}';
        final awp = await dbHelper.register(pseudo, 'Password123!');
        final profileId = awp.profile.id!;

        // 2. Set balance to 150 epts (so player can afford Brute Force Lite: 150 epts)
        final db = await dbHelper.db;
        await db.update('profiles', {'epts_balance': 150}, where: 'id = ?', whereArgs: [profileId]);

        // 3. Create Riverpod ProviderScope and pump StoreScreen
        final container = ProviderContainer();
        addTearDown(container.dispose);

        // Log user in
        await container.read(playerSessionProvider.notifier).login(pseudo, 'Password123!');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: StoreScreen()),
          ),
        );

        // Wait for StoreScreen's FutureBuilder to complete
        await settleAsync(tester);

        // Catalog lists Phishing Mailer v1 (owned) and Brute Force Lite.
        // Names render as authored, not upper-cased — the step 05 theme
        // migration dropped the manual uppercasing these assertions predated.
        expect(find.text('Phishing Mailer v1'), findsOneWidget);
        expect(find.text('OWNED'), findsOneWidget);
        expect(find.text('Brute Force Lite'), findsOneWidget);

        // 4. Test StoreItemScreen arguments loading and buying state
        final catalogRepo = CatalogRepository(dbHelper);
        final items = await catalogRepo.allSoftwareItems();
        final bruteForceItem = items.firstWhere((i) => i.id == 4);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              // Fresh key forces a new Navigator. Without it Flutter updates
              // the previous MaterialApp element in place, keeping the route
              // stack pushed from the old `home:` — onGenerateRoute is then
              // never consulted and the screen never mounts.
              key: UniqueKey(),
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  settings: RouteSettings(arguments: StoreItemArgs(item: bruteForceItem)),
                  builder: (_) => const StoreItemScreen(),
                );
              },
            ),
          ),
        );

        await settleAsync(tester);

        // Buy button should be enabled since balance (150) >= basePrice (150)
        final buyButtonFinder = find.byType(OutlinedButton);
        expect(buyButtonFinder, findsOneWidget);

        final OutlinedButton buttonWidget = tester.widget(buyButtonFinder);
        expect(buttonWidget.onPressed, isNotNull); // Button is enabled!

        // 5. Test Insufficient funds state: set balance to 0 and verify button is disabled
        await db.update('profiles', {'epts_balance': 0}, where: 'id = ?', whereArgs: [profileId]);

        // Trigger Riverpod session refresh
        await container.read(playerSessionProvider.notifier).refresh();
        await settleAsync(tester);

        // Re-fetch the button widget
        final OutlinedButton disabledButtonWidget = tester.widget(buyButtonFinder);
        expect(disabledButtonWidget.onPressed, isNull); // Button is disabled!
        expect(find.text('INSUFFICIENT EPTS BALANCE'), findsOneWidget);
      });
    });
  });
}

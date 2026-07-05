import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:men_in_the_middle/db/database_helper.dart';
import 'package:men_in_the_middle/screens/workshop_item_screen.dart';
import 'package:men_in_the_middle/state/player_session.dart';
import 'package:men_in_the_middle/utils/route_args.dart';
import 'package:men_in_the_middle/widgets/app_snack.dart';
import 'package:men_in_the_middle/widgets/game_scaffold.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'flutter/assets',
      (ByteData? message) async {
        if (message == null) return null;
        final key = utf8.decode(
          message.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        
        String filePath = '';
        if (key.contains('target_types.json')) {
          filePath = 'assets/data/catalog/target_types.json';
        } else if (key.contains('mission_types.json')) {
          filePath = 'assets/data/catalog/mission_types.json';
        } else if (key.contains('software_items.json')) {
          filePath = 'assets/data/catalog/software_items.json';
        } else if (key.contains('hardware_items.json')) {
          filePath = 'assets/data/catalog/hardware_items.json';
        } else if (key.contains('target_templates.json')) {
          filePath = 'assets/data/catalog/target_templates.json';
        } else if (key.contains('effectiveness.json')) {
          filePath = 'assets/data/catalog/effectiveness.json';
        } else if (key.contains('level_curve.json')) {
          filePath = 'assets/data/catalog/level_curve.json';
        } else if (key.contains('economy.json')) {
          filePath = 'assets/data/catalog/economy.json';
        } else if (key.contains('legends.json')) {
          filePath = 'assets/data/legends.json';
        }

        if (key.contains('AssetManifest')) {
          return const StandardMessageCodec().encodeMessage(<dynamic, dynamic>{});
        }

        if (filePath.isNotEmpty && File(filePath).existsSync()) {
          final bytes = File(filePath).readAsBytesSync();
          return ByteData.sublistView(bytes);
        }
        return null;
      },
    );
  });

  group('1. showAppSnack Widget Tests', () {
    testWidgets('showAppSnack displays floating snackbar with correct layout and clears previous ones', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => showAppSnack(context, 'FIRST SNACK', kind: AppSnackKind.info),
                    child: const Text('Show First'),
                  ),
                  ElevatedButton(
                    onPressed: () => showAppSnack(context, 'SECOND SNACK', kind: AppSnackKind.success),
                    child: const Text('Show Second'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Tap first button
      await tester.tap(find.text('Show First'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 500)); // Complete animation
      expect(find.text('FIRST SNACK'), findsOneWidget);

      // Tap second button
      await tester.tap(find.text('Show Second'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      
      // First snack should have been dismissed immediately
      expect(find.text('FIRST SNACK'), findsNothing);
      expect(find.text('SECOND SNACK'), findsOneWidget);

      final SnackBar snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.margin, const EdgeInsets.only(bottom: 80, left: 24, right: 24));
    });
  });

  group('2. GameScaffold Settings Icon Tests', () {
    testWidgets('renders settings icon when showSettings = true and hides when false', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScaffold(
              screenNum: '1.0',
              screenName: 'TEST SCREEN',
              showSettings: true,
              body: Text('Body Text'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GameScaffold(
              screenNum: '1.0',
              screenName: 'TEST SCREEN',
              showSettings: false,
              body: Text('Body Text'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsNothing);
    });
  });

  group('3. WorkshopItemScreen In-Place Upgrade Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      dbHelper.dbName = 'middlemen_workshop_widgets_${Random().nextInt(0x7FFFFFFF)}.db';
    });

    tearDown(() async {
      await dbHelper.close();
    });

    testWidgets('Upgrade keeps the player on the screen and re-renders stats in-place', (tester) async {
      await tester.runAsync(() async {
        print('--- TEST STEP: start');
        final pseudo = 'upgrade_agent_${Random().nextInt(0x7FFFFFFF)}';
        final awp = await dbHelper.register(pseudo, 'Password123!');
        final profileId = awp.profile.id!;
        print('--- TEST STEP: register profileId = $profileId');

        final db = await dbHelper.db;

        // Starter software Phishing Mailer v1, itemId: 1. Let's make sure player has enough epts (e.g. 500 epts)
        await db.update('profiles', {'epts_balance': 500}, where: 'id = ?', whereArgs: [profileId]);
        print('--- TEST STEP: set balance');

        final container = ProviderContainer();
        await container.read(playerSessionProvider.notifier).login(pseudo, 'Password123!');
        print('--- TEST STEP: login completed');

        // Get user software id
        final userSoft = await db.query('user_software', where: 'profile_id = ?', whereArgs: [profileId]);
        final userSoftId = userSoft.first['id'] as int;

        final args = WorkshopItemArgs(itemType: 'software', id: userSoftId);
        print('--- TEST STEP: args prepared = $userSoftId');

        // Pump WorkshopItemScreen
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              initialRoute: '/workshop',
              onGenerateRoute: (settings) {
                if (settings.name == '/workshop') {
                  return MaterialPageRoute(
                    builder: (_) => const WorkshopItemScreen(),
                    settings: RouteSettings(name: '/workshop', arguments: args),
                  );
                }
                if (settings.name == '/settings') {
                  return MaterialPageRoute(
                    builder: (_) => const Scaffold(body: Text('SETTINGS_PAGE')),
                  );
                }
                return null;
              },
            ),
          ),
        );
        print('--- TEST STEP: pumpWidget done');

        await tester.pump(); // Render loading indicator
        print('--- TEST STEP: pump 1 done');
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await tester.pump(); // Render item details screen
        // Renders starter specs: LEVEL 1/5
        expect(find.textContaining('LEVEL 1/5'), findsOneWidget);
        print('--- TEST STEP: LEVEL 1/5 verified');

        // Verify the upgrade button is present (UPGRADE · 100 EPTS)
        expect(find.text('UPGRADE · 100 EPTS'), findsOneWidget);
        print('--- TEST STEP: button verified');

        // Tap Upgrade
        await tester.tap(find.text('UPGRADE · 100 EPTS'));
        print('--- TEST STEP: button tapped');
        await tester.pump(); // Starts upgrade Future
        await Future<void>.delayed(const Duration(milliseconds: 300)); // Finish DB operations & session refresh
        await tester.pump(); // Render screen updates
        print('--- TEST STEP: final pump done');

        expect(find.textContaining('LEVEL 2/5'), findsOneWidget);
        expect(find.text('UPGRADE · 150 EPTS'), findsOneWidget);
        print('--- TEST STEP: LEVEL 2/5 verified');

        // Verify success snackbar shows up
        expect(find.text('UPGRADE COMPLETED SUCCESSFULLY'), findsOneWidget);
        print('--- TEST STEP: success snackbar verified');
      });
    });
  });
}

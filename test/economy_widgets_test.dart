import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Disable network google font lookups in tests
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
        } else if (key.contains('legends.json')) {
          filePath = 'assets/data/legends.json';
        }

        if (filePath.isNotEmpty && File(filePath).existsSync()) {
          final bytes = File(filePath).readAsBytesSync();
          return ByteData.sublistView(bytes);
        }
        return null;
      },
    );
  });

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
      // 1. Register and login player
      final pseudo = 'widget_eco_agent_${Random().nextInt(0x7FFFFFFF)}';
      final awp = await dbHelper.register(pseudo, 'Password123!');
      final profileId = awp.profile.id!;

      // 2. Set balance to 150 epts (so player can afford Brute Force Lite: 150 epts)
      final db = await dbHelper.db;
      await db.update('profiles', {'epts_balance': 150}, where: 'id = ?', whereArgs: [profileId]);

      // 3. Create Riverpod ProviderScope and pump StoreScreen
      final container = ProviderContainer();
      
      // Log user in
      await container.read(playerSessionProvider.notifier).login(pseudo, 'Password123!');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: StoreScreen(),
          ),
        ),
      );

      // Wait for StoreScreen's FutureBuilder to complete
      await tester.pumpAndSettle();

      // Check if catalog lists Phishing Mailer v1 (owned) and Brute Force Lite
      expect(find.text('PHISHING MAILER V1'), findsOneWidget);
      expect(find.text('BRUTE FORCE LITE'), findsOneWidget);

      // 4. Test StoreItemScreen arguments loading and buying state
      final catalogRepo = CatalogRepository(dbHelper);
      final items = await catalogRepo.allSoftwareItems();
      final bruteForceItem = items.firstWhere((i) => i.id == 4);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                settings: RouteSettings(
                  arguments: StoreItemArgs(item: bruteForceItem),
                ),
                builder: (_) => const StoreItemScreen(),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Buy button should be enabled since balance (150) >= basePrice (150)
      final buyButtonFinder = find.byType(OutlinedButton);
      expect(buyButtonFinder, findsOneWidget);
      
      final OutlinedButton buttonWidget = tester.widget(buyButtonFinder);
      expect(buttonWidget.onPressed, isNotNull); // Button is enabled!

      // 5. Test Insufficient funds state: set balance to 0 and verify button is disabled
      await db.update('profiles', {'epts_balance': 0}, where: 'id = ?', whereArgs: [profileId]);
      
      // Trigger Riverpod session refresh
      await container.read(playerSessionProvider.notifier).refresh();
      await tester.pumpAndSettle();

      // Re-fetch the button widget
      final OutlinedButton disabledButtonWidget = tester.widget(buyButtonFinder);
      expect(disabledButtonWidget.onPressed, isNull); // Button is disabled!
      expect(find.text('INSUFFICIENT EPTS BALANCE'), findsOneWidget);
    });
  });
}

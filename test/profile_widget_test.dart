import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:men_in_the_middle/db/database_helper.dart';
import 'package:men_in_the_middle/screens/profile_screen.dart';
import 'package:men_in_the_middle/state/player_session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Deliberately uses bounded tester.pump() calls instead of pumpAndSettle():
// this project's other ConsumerWidget + real-DB widget tests
// (economy_widgets_test.dart, target_board_widgets_test.dart) are known to
// hang indefinitely under pumpAndSettle for reasons not yet root-caused
// (see docs/planning/step_07_attack_flow.md Summary). Bounded pumps sidestep
// that risk regardless of the underlying cause.
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
          message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
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

  group('ProfileScreen', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      dbHelper.dbName = 'middlemen_profile_widget_${Random().nextInt(0x7FFFFFFF)}.db';
    });

    tearDown(() async {
      await dbHelper.close();
    });

    Future<void> pumpSettledish(WidgetTester tester) async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('renders identity, capabilities, reputation and empty history for a fresh agent',
        (tester) async {
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
      await pumpSettledish(tester);

      expect(find.text(pseudo), findsOneWidget);
      expect(find.textContaining('Mouse'), findsOneWidget);
      expect(find.text('${awp.profile.eptsBalance}'), findsOneWidget);
      expect(find.text('0 / 100'), findsOneWidget); // fresh profile: wanted = 0
      expect(find.text('No operations logged yet.'), findsOneWidget);
    });

    testWidgets('shows a recent operation after one is logged', (tester) async {
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
      await pumpSettledish(tester);

      expect(find.textContaining('Local Merchant PC'), findsOneWidget);
      expect(find.text('+80 EPTS'), findsOneWidget);
    });
  });
}

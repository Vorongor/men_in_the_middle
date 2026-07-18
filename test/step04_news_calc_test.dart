import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:men_in_the_middle/db/database_helper.dart';
import 'package:men_in_the_middle/game/resolution/attack_models.dart';
import 'package:men_in_the_middle/game/resolution/resolution_engine.dart';
import 'package:men_in_the_middle/models/active_contract.dart';
import 'package:men_in_the_middle/models/profile.dart';
import 'package:men_in_the_middle/models/software_item.dart';
import 'package:men_in_the_middle/models/user_software.dart';
import 'package:men_in_the_middle/repos/target_repository.dart';
import 'package:men_in_the_middle/screens/attack_prep_screen.dart';
import 'package:men_in_the_middle/screens/news_screen.dart';
import 'package:men_in_the_middle/services/news_state_service.dart';
import 'package:men_in_the_middle/state/player_session.dart';
import 'package:men_in_the_middle/utils/route_args.dart';
import 'package:men_in_the_middle/utils/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        } else if (key.contains('news_lore.json')) {
          filePath = 'assets/data/news_lore.json';
        } else if (key.contains('ShareTechMono-Regular.ttf') || key.contains('Cinzel-Regular.ttf')) {
          filePath = 'assets/fonts/GeistPixel-Regular-VariableFont_ELSH.ttf';
        }

        if (key.contains('AssetManifest')) {
          final manifest = {
            'assets/data/catalog/target_types.json': ['assets/data/catalog/target_types.json'],
            'assets/data/catalog/mission_types.json': ['assets/data/catalog/mission_types.json'],
            'assets/data/catalog/software_items.json': ['assets/data/catalog/software_items.json'],
            'assets/data/catalog/hardware_items.json': ['assets/data/catalog/hardware_items.json'],
            'assets/data/catalog/target_templates.json': ['assets/data/catalog/target_templates.json'],
            'assets/data/catalog/effectiveness.json': ['assets/data/catalog/effectiveness.json'],
            'assets/data/catalog/level_curve.json': ['assets/data/catalog/level_curve.json'],
            'assets/data/catalog/economy.json': ['assets/data/catalog/economy.json'],
            'assets/data/legends.json': ['assets/data/legends.json'],
            'assets/data/news_lore.json': ['assets/data/news_lore.json'],
            'google_fonts/ShareTechMono-Regular.ttf': ['google_fonts/ShareTechMono-Regular.ttf'],
            'google_fonts/Cinzel-Regular.ttf': ['google_fonts/Cinzel-Regular.ttf'],
          };
          return const StandardMessageCodec().encodeMessage(manifest);
        }

        if (filePath.isNotEmpty && File(filePath).existsSync()) {
          final bytes = File(filePath).readAsBytesSync();
          return ByteData.sublistView(bytes);
        }
        return null;
      },
    );
  });

  group('1. NewsStateService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads empty lists and updates/persists states correctly', () async {
      final service = NewsStateService.instance;
      await service.load();

      expect(service.isRead('test_1'), isFalse);
      expect(service.isDismissed('test_1'), isFalse);

      await service.markAsRead('test_1');
      expect(service.isRead('test_1'), isTrue);

      await service.dismiss('test_1');
      expect(service.isDismissed('test_1'), isTrue);

      await service.dismissMultiple(['test_2', 'test_3']);
      expect(service.isDismissed('test_2'), isTrue);
      expect(service.isDismissed('test_3'), isTrue);

      await service.load();
      expect(service.isRead('test_1'), isTrue);
      expect(service.isDismissed('test_1'), isTrue);
      expect(service.isDismissed('test_2'), isTrue);
      expect(service.isDismissed('test_3'), isTrue);

      await service.undismiss('test_1');
      expect(service.isDismissed('test_1'), isFalse);

      await service.undismissMultiple(['test_2', 'test_3']);
      expect(service.isDismissed('test_2'), isFalse);
      expect(service.isDismissed('test_3'), isFalse);
    });
  });

  group('2. ResolutionEngine Forecast Unit Tests', () {
    final profile = Profile(
      id: 1,
      profileId: 'Agent',
      levelId: 1,
      hardwarePower: 100,
      wanted: 0,
      blackTrust: 10,
      legend: 'Mouse',
    );

    final contract = ContractDetails(
      id: 10,
      profileId: 1,
      targetTemplateId: 1,
      missionTypeId: 1,
      defense: 100,
      eptsReward: 50,
      trustReward: 5,
      isCompleted: false,
      targetName: 'MegaCorp Subordinate',
      targetRequiredLevel: 1,
      customMechanicsJson: '{}',
      targetTypeId: 1,
      targetTypeName: 'Corporate',
      targetBaseTraceSpeed: 10,
      targetRiskMultiplier: 1.0,
      missionName: 'Steal Client List',
      missionDescription: 'Download data',
      missionPrimarySoftTypeId: 1,
    );

    final softwareItem = SoftwareItem(
      id: 100,
      name: 'Shadowphish',
      softTypeId: 1,
      description: 'Phishing software',
      basePrice: 200,
      baseAttack: 50,
      basePenetration: 5,
      baseTrace: 15,
      levelUpStrategy: {},
    );

    test('ResolutionEngine calculates correct Power Ratio and Trace Risk', () {
      final userSoftware = UserSoftware(
        id: 500,
        profileId: 1,
        itemId: 100,
        attack: 120,
        penetrationAbility: 10,
        residualTrace: 25,
      );

      final owned = OwnedSoftware(
        userSoftware: userSoftware,
        catalogItem: softwareItem,
      );

      final setup = AttackSetup(
        profile: profile,
        contract: contract,
        selectedSoftware: owned,
        hardwarePower: 100,
        damageMult: 1.2,
        traceMult: 1.5,
      );

      expect(ResolutionEngine.effectiveAttack(setup), equals(144));
      expect(ResolutionEngine.powerRatio(setup), closeTo(1.44, 0.01));
      expect(ResolutionEngine.traceRisk(setup), closeTo(37.5, 0.01));
    });
  });

  group('3. NewsScreen Widget Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await NewsStateService.instance.load();
      dbHelper = DatabaseHelper.instance;
      dbHelper.dbName = 'middlemen_news_test_${Random().nextInt(0x7FFFFFFF)}.db';
    });

    tearDown(() async {
      await dbHelper.close();
    });

    testWidgets('News feed loads articles, dims read ones, dismisses on swipe and clear read', (tester) async {
      await tester.runAsync(() async {
        final pseudo = 'news_agent_${Random().nextInt(0x7FFFFFFF)}';
        final awp = await dbHelper.register(pseudo, 'Password123!');
        final profileId = awp.profile.id!;

        final db = await dbHelper.db;

        // Insert recent operations logs
        await db.insert('attack_log', {
          'profile_id': profileId,
          'target_template_id': 1,
          'mission_type_id': 1,
          'result': 'success',
          'epts_delta': 10,
          'wanted_delta': 0,
          'trust_delta': 2,
          'created_at': '2026-07-06 12:00:00',
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(playerSessionProvider.notifier).login(pseudo, 'Password123!');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              routes: {
                Routes.news: (context) => const NewsScreen(),
                Routes.newsItem: (context) => Scaffold(
                  body: Center(
                    child: Text('News Detail: ${(ModalRoute.of(context)!.settings.arguments as NewsItemArgs).article.title}'),
                  ),
                ),
              },
              home: const NewsScreen(),
            ),
          ),
        );

        // Wait for FutureBuilder to resolve (on real event loop)
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // Check if recent log headline is visible
        expect(find.textContaining('Confirms Clean Data Breach'), findsOneWidget);

        // Tap the article to read it
        await tester.tap(find.textContaining('Confirms Clean Data Breach'));
        await tester.pump();
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Verify navigated to details
        expect(find.textContaining('News Detail:'), findsOneWidget);

        // Go back
        Navigator.pop(tester.element(find.textContaining('News Detail:')));
        await tester.pump();
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // Verifying read status dims the row (opacity check on parent wrapper)
        final opacityFinder = find.ancestor(
          of: find.textContaining('Confirms Clean Data Breach'),
          matching: find.byType(Opacity),
        );
        expect(opacityFinder, findsOneWidget);
        final opacityWidget = tester.widget<Opacity>(opacityFinder.first);
        expect(opacityWidget.opacity, equals(0.4));

        // The "CLEAR READ" button should be visible since there's a read article
        expect(find.text('CLEAR READ'), findsOneWidget);

        // Swipe to dismiss another article (e.g. MegaCorp Servers Breached)
        expect(find.text('MegaCorp Servers Breached'), findsOneWidget);
        await tester.drag(find.text('MegaCorp Servers Breached'), const Offset(-500, 0));
        await tester.pump();
        // Wait for dismiss and snackbar entrance animations to complete
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Verify "ARTICLE DISMISSED" snackbar shown and article removed
        expect(find.text('ARTICLE DISMISSED'), findsOneWidget);
        expect(find.text('MegaCorp Servers Breached'), findsNothing);

        // Tap UNDO on the snackbar
        await tester.tap(find.text('UNDO'));
        await tester.pump();
        // Wait for undismiss to execute
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump(); // trigger setState(_load) rebuild
        // Wait for _loadFuture database query to complete
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump(); // rebuilds with restored item
        // Wait for snackbar to settle / animate
        for (int i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Verify article restored
        expect(find.text('MegaCorp Servers Breached'), findsOneWidget);

        // Tap "CLEAR READ" to bulk dismiss
        await tester.tap(find.text('CLEAR READ'));
        await tester.pump();
        // Wait for bulk dismiss to execute
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump(); // trigger setState(_load) rebuild
        // Wait for _loadFuture database query to complete
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump(); // rebuilds with read article removed
        // Let the snackbar entrance animation complete
        for (int i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Verify "CLEARED 1 READ ARTICLES" snackbar shown and read item removed
        expect(find.text('CLEARED 1 READ ARTICLES'), findsOneWidget);
        expect(find.textContaining('Confirms Clean Data Breach'), findsNothing);

        // Tap UNDO for clear read
        await tester.tap(find.text('UNDO'));
        await tester.pump();
        // Wait for undismissMultiple to execute
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump(); // trigger setState(_load) rebuild
        // Wait for _loadFuture database query to complete
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump(); // rebuilds with restored items
        for (int i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Verify restored
        expect(find.textContaining('Confirms Clean Data Breach'), findsOneWidget);
      });
    });
  });

  group('4. AttackPrepScreen Forecast Panel Widget Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      dbHelper.dbName = 'middlemen_prep_test_${Random().nextInt(0x7FFFFFFF)}.db';
    });

    tearDown(() async {
      await dbHelper.close();
    });

    testWidgets('Renders Forecast panel values and reacts to compatible/incompatible selection', (tester) async {
      await tester.runAsync(() async {
        final pseudo = 'prep_agent_${Random().nextInt(0x7FFFFFFF)}';
        final awp = await dbHelper.register(pseudo, 'Password123!');
        final profileId = awp.profile.id!;

        final db = await dbHelper.db;

        // Insert another software: Type 2 malware (e.g. itemId = 2, softTypeId = 2 System Hijack)
        await db.insert('user_software', {
          'profile_id': profileId,
          'item_id': 2,
          'current_level': 1,
          'attack': 120,
          'penetration_ability': 20,
          'residual_trace': 30,
          'modificator_sockets': 1,
        });

        final targetRepo = TargetRepository(dbHelper);
        await targetRepo.refreshContracts(awp.profile, customSeed: 12, ownedSoftTypeIds: const [1, 2]);
        final contracts = await targetRepo.fetchActiveContracts(profileId);
        final contractId = contracts.first.id;

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(playerSessionProvider.notifier).login(pseudo, 'Password123!');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              initialRoute: '/prep',
              onGenerateRoute: (settings) {
                if (settings.name == '/prep') {
                  return MaterialPageRoute(
                    builder: (context) => const AttackPrepScreen(),
                    settings: RouteSettings(
                      name: '/prep',
                      arguments: AttackPrepArgs(contractId: contractId),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        );

        // Wait for FutureBuilder to resolve (on real event loop)
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await tester.pump();

        // Forecast panel should be visible
        expect(find.text('ATTACK FORECAST'), findsOneWidget);
        expect(find.text('Effective Attack'), findsOneWidget);
        expect(find.text('Power Ratio'), findsOneWidget);
        expect(find.text('Trace Risk'), findsOneWidget);
        expect(find.text('Verdict'), findsOneWidget);

        // Tap the other software item (incompatible or compatible depending on primary soft type)
        final incompatibleFinder = find.text('INCOMPATIBLE');
        if (tester.any(incompatibleFinder)) {
          final rowFinder = find.ancestor(of: incompatibleFinder, matching: find.byType(InkWell));
          await tester.tap(rowFinder.first);
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await tester.pump();

          // Verify warning / SUICIDE (tool mismatch) verdict shows up due to 0.2 damageMult
          expect(find.text('SUICIDE (tool mismatch)'), findsOneWidget);
        }
      });
    });
  });
}

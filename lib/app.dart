import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'screens/attack_prep_screen.dart';
import 'screens/attack_result_screen.dart';
import 'screens/attack_screen.dart';
import 'screens/debug_sniffer_screen.dart';
import 'screens/home_page_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/market_item_screen.dart';
import 'screens/market_screen.dart';
import 'screens/news_item_screen.dart';
import 'screens/news_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/store_item_screen.dart';
import 'screens/store_screen.dart';
import 'screens/target_board_screen.dart';
import 'screens/target_detail_screen.dart';
import 'screens/workshop_item_screen.dart';
import 'screens/workshop_screen.dart';
import 'utils/routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The MiddleMen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: Routes.home,
      routes: {
        // Pre-game
        Routes.home: (_) => const HomeScreen(),
        Routes.login: (_) => const LoginScreen(),
        Routes.settings: (_) => const SettingsScreen(),

        // In-game hub
        Routes.homePage: (_) => const HomePageScreen(),
        Routes.profile: (_) => const ProfileScreen(),

        // Target flow
        Routes.targetBoard: (_) => const TargetBoardScreen(),
        Routes.targetDetail: (_) => const TargetDetailScreen(),

        // Attack chain
        Routes.attackPrep: (_) => const AttackPrepScreen(),
        Routes.attackPlay: (_) => const AttackScreen(),
        Routes.attackResult: (_) => const AttackResultScreen(),

        // Store
        Routes.store: (_) => const StoreScreen(),
        Routes.storeItem: (_) => const StoreItemScreen(),

        // Market
        Routes.market: (_) => const MarketScreen(),
        Routes.marketItem: (_) => const MarketItemScreen(),

        // Workshop
        Routes.workshop: (_) => const WorkshopScreen(),
        Routes.workshopItem: (_) => const WorkshopItemScreen(),

        // News
        Routes.news: (_) => const NewsScreen(),
        Routes.newsItem: (_) => const NewsItemScreen(),

        // Debug-only
        if (kDebugMode) Routes.debugSniffer: (_) => const DebugSnifferScreen(),
      },
    );
  }
}

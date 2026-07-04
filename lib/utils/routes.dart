class Routes {
  // Pre-game
  static const home = '/';
  static const settings = '/settings';
  static const login = '/login';

  // In-game hub
  static const homePage = '/home-page';       // Screen 3
  static const profile = '/profile';          // Screen 4

  // Target flow
  static const targetBoard = '/targets';      // Screen 5.1
  static const targetDetail = '/targets/detail'; // Screen 5.2

  // Attack chain
  static const attackPrep = '/attack/prep';   // Screen 7.1
  static const attackPlay = '/attack/play';   // Screen 7.2
  static const attackResult = '/attack/result'; // Screen 7.3

  // Stores
  static const store = '/store';              // Screen 6.1
  static const storeItem = '/store/item';     // Screen 6.2
  static const market = '/market';            // Screen 8.1
  static const marketItem = '/market/item';   // Screen 8.2

  // Workshop
  static const workshop = '/workshop';        // Screen 9.1
  static const workshopItem = '/workshop/item'; // Screen 9.2

  // News
  static const news = '/news';               // Screen 10.1
  static const newsItem = '/news/item';      // Screen 10.2

  // Debug-only (kDebugMode)
  static const debugSniffer = '/debug/sniffer';
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show StandardMessageCodec;
import 'package:flutter_test/flutter_test.dart';

/// Catalog assets the seeder loads at DB init, mapped to their on-disk paths.
///
/// Kept in one place deliberately: this map used to be copy-pasted into every
/// widget test, and when `economy.json` was added the copies drifted — the
/// tests that were already hanging never got updated, so fixing the hang
/// immediately surfaced an "Unable to load asset" failure underneath it.
const _catalogAssets = <String, String>{
  'target_types.json': 'assets/data/catalog/target_types.json',
  'mission_types.json': 'assets/data/catalog/mission_types.json',
  'software_items.json': 'assets/data/catalog/software_items.json',
  'hardware_items.json': 'assets/data/catalog/hardware_items.json',
  'target_templates.json': 'assets/data/catalog/target_templates.json',
  'effectiveness.json': 'assets/data/catalog/effectiveness.json',
  'level_curve.json': 'assets/data/catalog/level_curve.json',
  'economy.json': 'assets/data/catalog/economy.json',
  'legends.json': 'assets/data/legends.json',
  'news_lore.json': 'assets/data/news_lore.json',
};

/// Fonts the theme requests through `google_fonts` at runtime.
///
/// The app deliberately fetches Share Tech Mono over the network (decision
/// recorded in step 05), which tests can't do: with
/// `allowRuntimeFetching = false` google_fonts *throws* during build unless
/// the font resolves from assets, and that aborts the whole screen render.
/// Serving the bundled GeistPixel bytes under the requested name satisfies the
/// loader — layout metrics differ from the real font, so assert on text and
/// keys, never on pixel geometry.
const _fontStandIn = 'assets/fonts/GeistPixel-Regular-VariableFont_ELSH.ttf';
const _googleFontKeys = <String>[
  'google_fonts/ShareTechMono-Regular.ttf',
  'google_fonts/Cinzel-Regular.ttf',
];

/// Serves the real catalog JSON files from disk to code that reads them via
/// `rootBundle`. Call from `setUpAll()`.
void mockCatalogAssetBundle() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
    if (message == null) return null;
    final key = utf8.decode(
      message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
    );

    // This handler replaces the whole asset channel, so it also fields the
    // framework's own lookups. The manifest must list every key we serve —
    // returning null (or an empty map) makes font resolution throw during
    // build, and the screen then never renders its content.
    if (key.contains('AssetManifest')) {
      final manifest = <String, List<String>>{
        for (final path in _catalogAssets.values) path: [path],
        for (final font in _googleFontKeys) font: [font],
      };
      return const StandardMessageCodec().encodeMessage(manifest);
    }

    if (_googleFontKeys.any((f) => key.contains(f.split('/').last))) {
      return ByteData.sublistView(File(_fontStandIn).readAsBytesSync());
    }

    for (final entry in _catalogAssets.entries) {
      if (!key.contains(entry.key)) continue;
      final file = File(entry.value);
      if (!file.existsSync()) return null;
      return ByteData.sublistView(file.readAsBytesSync());
    }
    return null;
  });
}

/// Advances a widget under test that depends on **real** asynchronous work
/// (database reads, repository futures) rather than fake-clock timers.
///
/// Why this exists: a `testWidgets` body runs inside a FakeAsync zone whose
/// clock only moves when the test pumps. Real sqflite I/O never completes
/// there, so `await`ing it deadlocks the isolate — not even the dart-test
/// timeout fires, because that is itself a Dart timer on the blocked event
/// loop. The cure is to run such bodies inside `tester.runAsync()`.
///
/// Inside `runAsync()` the fake clock is bypassed, which also makes
/// `pumpAndSettle()` unreliable: it wants to drain a frame queue that real
/// futures are not feeding. This helper is the replacement — let real time
/// pass so pending futures resolve, then pump to rebuild.
///
/// Prefer raising [rounds] over lengthening [step]: several short waits give
/// chained futures (query → provider → rebuild → query) a chance to unwind,
/// where one long wait only covers the first link.
Future<void> settleAsync(
  WidgetTester tester, {
  int rounds = 4,
  Duration step = const Duration(milliseconds: 150),
}) async {
  for (var i = 0; i < rounds; i++) {
    // Real wait lets the pending I/O future resolve...
    await Future<void>.delayed(step);
    // ...and pumping *with a duration* advances the binding clock, which is
    // what drives route transitions and other animations. A bare pump() only
    // rebuilds, so a screen pushed via onGenerateRoute would stay mid-
    // transition and render as an empty tree.
    await tester.pump(step);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'app.dart';
import 'services/audio_service.dart';
import 'services/news_state_service.dart';
import 'services/settings_service.dart';
import 'utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  MediaKit.ensureInitialized();
  await SettingsService.instance.load();
  await NewsStateService.instance.load();
  await AudioService.instance.startBgm();
  runApp(const ProviderScope(child: App()));
}

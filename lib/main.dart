import 'package:flutter/material.dart';
import 'app.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService.instance.startBgm();
  runApp(const App());
}

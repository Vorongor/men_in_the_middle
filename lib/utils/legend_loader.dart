import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

Future<String> pickRandomLegend() async {
  final raw = await rootBundle.loadString('assets/data/legends.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final list = decoded['hacker_legends'] as List<dynamic>;
  final entry = list[Random().nextInt(list.length)] as Map<String, dynamic>;
  return entry['legend'] as String;
}

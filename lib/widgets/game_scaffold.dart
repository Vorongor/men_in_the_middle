import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/player_session.dart';
import '../utils/async_value_ext.dart';
import '../utils/routes.dart';

class GameScaffold extends ConsumerWidget {
  const GameScaffold({
    super.key,
    required this.screenNum,
    required this.screenName,
    required this.body,
    this.showHomeButton = true,
    this.hideBackButton = false,
  });

  final String screenNum;
  final String screenName;
  final Widget body;
  final bool showHomeButton;
  final bool hideBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider).valueOrNull;
    final balance = session?.profile.eptsBalance;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        foregroundColor: Colors.white70,
        automaticallyImplyLeading: !hideBackButton,
        centerTitle: true,
        title: Text(
          screenName,
          style: GoogleFonts.cinzel(
            fontSize: 13,
            letterSpacing: 2,
            color: Colors.white70,
          ),
        ),
        actions: [
          if (balance != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C160C),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF1E351E)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.currency_bitcoin, color: Colors.greenAccent, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '$balance epts',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.greenAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (showHomeButton)
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 20),
              tooltip: 'Home',
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.homePage,
                (r) => false,
              ),
            ),
        ],
      ),
      body: body,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppSnackKind { success, error, info }

void showAppSnack(
  BuildContext context,
  String message, {
  AppSnackKind kind = AppSnackKind.info,
}) {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  // Clear existing snackbars to prevent stacking (resolves bug #3)
  scaffoldMessenger.clearSnackBars();

  Color bgColor;
  Color textColor;
  switch (kind) {
    case AppSnackKind.success:
      bgColor = const Color(0xFF0C160C);
      textColor = Colors.greenAccent;
      break;
    case AppSnackKind.error:
      bgColor = const Color(0xFF240C0C);
      textColor = Colors.redAccent;
      break;
    case AppSnackKind.info:
      bgColor = const Color(0xFF0D0D0D);
      textColor = Colors.white70;
      break;
  }

  scaffoldMessenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 80, left: 24, right: 24),
      backgroundColor: bgColor,
      duration: const Duration(seconds: 2),
      dismissDirection: DismissDirection.down,
      content: Text(
        message,
        style: GoogleFonts.shareTechMono(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    ),
  );
}

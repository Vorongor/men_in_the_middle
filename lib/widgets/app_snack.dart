import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppSnackKind { success, error, info }

void showAppSnack(
  BuildContext context,
  String message, {
  AppSnackKind kind = AppSnackKind.info,
  SnackBarAction? action,
}) {
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  // Clear existing snackbars to prevent stacking (resolves bug #3)
  scaffoldMessenger.clearSnackBars();

  Color bgColor;
  Color textColor;
  switch (kind) {
    case AppSnackKind.success:
      bgColor = AppColors.surfaceSuccess;
      textColor = AppColors.primary;
      break;
    case AppSnackKind.error:
      bgColor = AppColors.surfaceError;
      textColor = AppColors.alert;
      break;
    case AppSnackKind.info:
      bgColor = AppColors.surface;
      textColor = AppColors.text;
      break;
  }

  scaffoldMessenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 80, left: 24, right: 24),
      backgroundColor: bgColor,
      duration: const Duration(seconds: 2),
      dismissDirection: DismissDirection.down,
      action: action,
      content: Text(
        message,
        style: AppTextStyles.snackMessage(color: textColor),
      ),
    ),
  );
}

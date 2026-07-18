import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/player_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
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
    this.showSettings = true,
  });

  final String screenNum;
  final String screenName;
  final Widget body;
  final bool showHomeButton;
  final bool hideBackButton;
  final bool showSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider).valueOrNull;
    final balance = session?.profile.eptsBalance;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        automaticallyImplyLeading: !hideBackButton,
        centerTitle: true,
        title: Text(
          screenName,
          style: AppTextStyles.sectionLabel(color: AppColors.text),
        ),
        actions: [
          if (balance != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSuccess,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.borderSuccess),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.currency_bitcoin,
                        color: AppColors.primary,
                        size: 12,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '$balance epts',
                        style: AppTextStyles.dataMono(color: AppColors.primary)
                            .copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (showSettings)
            IconButton(
              icon: const Icon(Icons.settings, size: 20),
              tooltip: 'Settings',
              onPressed: () => Navigator.pushNamed(context, Routes.settings),
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

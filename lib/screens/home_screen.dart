import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../widgets/video_bg.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          VideoBg(fallback: AppImages.homeBg),
          const ColoredBox(color: AppColors.scrim),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.gameTitle,
                  style: AppTextStyles.displayTitle(color: AppColors.primary).copyWith(
                    fontSize: 42,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 64),
                _MenuButton(
                  label: 'Start',
                  onTap: () => Navigator.pushNamed(context, Routes.login),
                ),
                const SizedBox(height: AppSpacing.xl),
                _MenuButton(
                  label: 'Settings',
                  onTap: () => Navigator.pushNamed(context, Routes.settings),
                ),
                const SizedBox(height: AppSpacing.xl),
                _MenuButton(
                  label: 'Exit',
                  onTap: SystemNavigator.pop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.35 : 1.0,
      child: SizedBox(
        width: 220,
        height: 52,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.button(color: AppColors.primary).copyWith(
              fontSize: 20,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}

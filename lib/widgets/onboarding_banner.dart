import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repos/onboarding_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// A one-time dismissible tip, shown floating over a screen's content until
/// the player closes it — then never again (tracked via [OnboardingRepository]
/// / the `meta` table). This is the alpha's onboarding-minimum (Step 10 §10.2);
/// a full guided tutorial is out of scope.
///
/// Usage: wrap a screen's `body` in a `Stack` with this as the last child, e.g.
/// `body: Stack(children: [originalBody, OnboardingTip(tipKey: 'home', message: '...')])`.
class OnboardingTip extends ConsumerStatefulWidget {
  const OnboardingTip({super.key, required this.tipKey, required this.message});

  final String tipKey;
  final String message;

  @override
  ConsumerState<OnboardingTip> createState() => _OnboardingTipState();
}

class _OnboardingTipState extends ConsumerState<OnboardingTip> {
  late Future<bool> _hasSeenFuture;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _hasSeenFuture = ref.read(onboardingRepositoryProvider).hasSeen(widget.tipKey);
  }

  void _dismiss() {
    setState(() => _dismissed = true);
    ref.read(onboardingRepositoryProvider).markSeen(widget.tipKey);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return FutureBuilder<bool>(
      future: _hasSeenFuture,
      builder: (context, snapshot) {
        if (snapshot.data != false) return const SizedBox.shrink();

        return Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSuccess,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.borderSuccess),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: AppTextStyles.body(color: AppColors.textHigh).copyWith(
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    InkWell(
                      onTap: _dismiss,
                      child: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

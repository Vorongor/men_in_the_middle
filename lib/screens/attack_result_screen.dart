import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/resolution/attack_models.dart';
import '../services/audio_service.dart';
import '../state/attack_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../widgets/game_scaffold.dart';
import '../widgets/onboarding_banner.dart';

class AttackResultScreen extends ConsumerStatefulWidget {
  const AttackResultScreen({super.key});

  @override
  ConsumerState<AttackResultScreen> createState() => _AttackResultScreenState();
}

class _AttackResultScreenState extends ConsumerState<AttackResultScreen> {
  Future<void>? _applyFuture;

  @override
  void initState() {
    super.initState();
    _applyFuture = ref
        .read(attackSessionProvider.notifier)
        .applyAndRefreshSession()
        .then((_) {
          final leveledUp =
              ref.read(attackSessionProvider).applyResult?.leveledUp ?? false;
          if (leveledUp) {
            unawaited(AudioService.instance.playSfx(AppAudio.sfxLevelUp));
          }
        });
  }

  void _leave(String route) {
    ref.read(attackSessionProvider.notifier).reset();
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      route == Routes.homePage
          ? (r) => false
          : (r) => r.settings.name == Routes.homePage,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _applyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const GameScaffold(
            screenNum: '7.3',
            screenName: 'ATTACK RESULT',
            showHomeButton: false,
            hideBackButton: true,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = ref.watch(attackSessionProvider);
        final resolution = session.resolution;
        if (resolution == null) {
          return GameScaffold(
            screenNum: '7.3',
            screenName: 'ATTACK RESULT',
            showHomeButton: false,
            hideBackButton: true,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No attack result to show.',
                    style: AppTextStyles.body(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => _leave(Routes.homePage),
                    child: const Text('HOME'),
                  ),
                ],
              ),
            ),
          );
        }

        final isHoneypot = session.setup?.contract.isHoneypot ?? false;
        final isSuccess = resolution.result != AttackResultKind.fail;
        final headline = switch (resolution.result) {
          AttackResultKind.success => 'OPERATION SUCCESS',
          AttackResultKind.hard => 'OPERATION SUCCESS — TRACED',
          AttackResultKind.fail =>
            isHoneypot ? 'IT WAS A TRAP' : 'OPERATION FAILED',
        };
        final accent = isSuccess ? AppColors.primary : AppColors.alert;
        final boxColor = isSuccess
            ? AppColors.surfaceSuccess
            : AppColors.surfaceError;
        final borderColor = isSuccess
            ? AppColors.borderSuccess
            : AppColors.alert.withValues(alpha: 0.3);

        final leveledUp = session.applyResult?.leveledUp ?? false;
        final newLevelName = session.applyResult?.newLevelName;

        return GameScaffold(
          screenNum: '7.3',
          screenName: 'ATTACK RESULT',
          showHomeButton: false,
          hideBackButton: true,
          body: Stack(
            children: [
              _resultBody(
                isSuccess: isSuccess,
                boxColor: boxColor,
                borderColor: borderColor,
                accent: accent,
                headline: headline,
                isHoneypot: isHoneypot,
                leveledUp: leveledUp,
                newLevelName: newLevelName,
                resolution: resolution,
              ),
              const OnboardingTip(
                tipKey: 'first_result',
                message:
                    'Spend your EPTS in the Store or Market, then '
                    'upgrade gear in the Workshop before your next job.',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _resultBody({
    required bool isSuccess,
    required Color boxColor,
    required Color borderColor,
    required Color accent,
    required String headline,
    required bool isHoneypot,
    required bool leveledUp,
    required String? newLevelName,
    required AttackResolution resolution,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: boxColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Column(
              children: [
                Icon(
                  isSuccess
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: accent,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  headline,
                  style: AppTextStyles.sectionLabel(color: accent).copyWith(
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          if (isHoneypot) ...[
            const SizedBox(height: 12),
            Text(
              'That contract was bait — a honeypot planted while your '
              'heat was running high. No amount of preparation would '
              'have saved this one.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(color: AppColors.textMuted).copyWith(
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
          if (leveledUp) ...[
            const SizedBox(height: 12),
            Text(
              'RANK UP: ${newLevelName ?? '?'}',
              style: AppTextStyles.sectionLabel(color: AppColors.warning).copyWith(
                fontSize: 13,
                letterSpacing: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _ResultRow('Credits', _signed(resolution.eptsDelta), suffix: ' EPTS'),
          _ResultRow('XP Gained', _signed(resolution.expDelta)),
          _ResultRow('Wanted', _signed(resolution.wantedDelta)),
          _ResultRow('Black Trust', _signed(resolution.trustDelta)),
          if (resolution.drops.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...resolution.drops.map(
              (d) => Text(
                d,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(color: AppColors.warning).copyWith(fontSize: 12),
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _leave(Routes.targetBoard),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textHigh,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'BACK TO TARGETS',
                style: AppTextStyles.button(color: AppColors.textHigh).copyWith(fontSize: 12, letterSpacing: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _leave(Routes.homePage),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'HOME',
                style: AppTextStyles.button(color: AppColors.textMuted).copyWith(fontSize: 12, letterSpacing: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  String _signed(int value) => value > 0 ? '+$value' : '$value';
}

class _ResultRow extends StatelessWidget {
  const _ResultRow(this.label, this.value, {this.suffix = ''});
  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final positive = !value.startsWith('-') && value != '0';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.body(color: AppColors.textMuted),
            ),
          ),
          Text(
            '$value$suffix',
            style: AppTextStyles.dataMono(
              color: positive ? AppColors.primary : AppColors.textHigh,
            ),
          ),
        ],
      ),
    );
  }
}

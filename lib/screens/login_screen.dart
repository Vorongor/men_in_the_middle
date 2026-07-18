import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/player_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_logger.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../widgets/app_snack.dart';
import '../widgets/video_bg.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static final _log = AppLogger.of('LoginScreen');

  final _pseudoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _pseudoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    showAppSnack(context, msg, kind: AppSnackKind.error);
  }

  Future<void> _onEnter() async {
    setState(() => _loading = true);
    final nav = Navigator.of(context);
    try {
      final ok = await ref
          .read(playerSessionProvider.notifier)
          .login(_pseudoCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (ok) {
        unawaited(nav.pushReplacementNamed(Routes.homePage));
      } else {
        _showError(AppErrors.wrongCredentials);
      }
    } catch (e) {
      _log.warning('Login failed', e);
      if (mounted) _showError(AppErrors.dbFail);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onFirstIn() async {
    setState(() => _loading = true);
    final nav = Navigator.of(context);
    try {
      await ref
          .read(playerSessionProvider.notifier)
          .register(_pseudoCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      unawaited(nav.pushReplacementNamed(Routes.homePage));
    } catch (e) {
      _log.warning('Registration failed', e);
      if (mounted) _showError(AppErrors.dbFail);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          VideoBg(fallback: AppImages.loginBg),
          const ColoredBox(color: Color(0xAA000000)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _InputField(controller: _pseudoCtrl, label: 'Pseudo'),
                  const SizedBox(height: AppSpacing.lg),
                  _InputField(controller: _passCtrl, label: 'Pass', obscure: true),
                  const SizedBox(height: 40),
                  _ActionButton(
                    label: 'Enter',
                    onTap: _loading ? null : _onEnter,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ActionButton(
                    label: 'First In',
                    onTap: _loading ? null : _onFirstIn,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: AppTextStyles.body(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }
}

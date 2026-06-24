import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../db/database_helper.dart';
import '../services/audio_service.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';

String _hashPassword(String raw) => sha256.convert(utf8.encode(raw)).toString();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[900],
      ),
    );
  }

  Future<void> _onEnter() async {
    setState(() => _loading = true);
    final nav = Navigator.of(context);
    try {
      final hash = _hashPassword(_passCtrl.text);
      final account = await DatabaseHelper.instance.login(_pseudoCtrl.text.trim(), hash);
      if (!mounted) return;
      if (account != null) {
        await AudioService.instance.stopBgm();
        nav.pushReplacementNamed(Routes.dashboard, arguments: account);
      } else {
        _showError(AppErrors.wrongCredentials);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onFirstIn() async {
    setState(() => _loading = true);
    final nav = Navigator.of(context);
    try {
      final hash = _hashPassword(_passCtrl.text);
      final account = await DatabaseHelper.instance.register(_pseudoCtrl.text.trim(), hash);
      if (!mounted) return;
      await AudioService.instance.stopBgm();
      nav.pushReplacementNamed(Routes.dashboard, arguments: account);
    } catch (_) {
      if (mounted) _showError(AppErrors.dbFail);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppImages.loginBg, fit: BoxFit.cover),
          const ColoredBox(color: Color(0xAA000000)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _InputField(controller: _pseudoCtrl, label: 'Pseudo'),
                  const SizedBox(height: 16),
                  _InputField(controller: _passCtrl, label: 'Pass', obscure: true),
                  const SizedBox(height: 40),
                  _ActionButton(
                    label: 'Enter',
                    onTap: _loading ? null : _onEnter,
                  ),
                  const SizedBox(height: 20),
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
  const _InputField({required this.controller, required this.label, this.obscure = false});

  final TextEditingController controller;
  final String label;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white38),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 1.5),
        ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 20, letterSpacing: 2)),
      ),
    );
  }
}

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/constants.dart';
import '../widgets/video_bg.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _muteAll;
  late double _general;
  late double _music;
  late double _effects;

  @override
  void initState() {
    super.initState();
    final s = SettingsService.instance;
    _muteAll = s.muteAll;
    _general = s.generalVolume;
    _music = s.musicVolume;
    _effects = s.effectsVolume;
  }

  Future<void> _onBack() async {
    final s = SettingsService.instance;
    s.muteAll = _muteAll;
    s.generalVolume = _general;
    s.musicVolume = _music;
    s.effectsVolume = _effects;
    await s.save();
    await FlameAudio.bgm.audioPlayer.setVolume(s.effectiveMusicVolume);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          VideoBg(fallback: AppImages.homeBg),
          const ColoredBox(color: Color(0x88000000)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Settings',
                    style: AppTextStyles.displayTitle(color: AppColors.primary).copyWith(
                      fontSize: 28,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _ToggleButton(
                    label: 'Mute All',
                    active: _muteAll,
                    onTap: () => setState(() => _muteAll = !_muteAll),
                  ),
                  const SizedBox(height: 32),
                  _VolumeSlider(
                    label: 'General',
                    value: _general,
                    onChanged: (v) => setState(() => _general = v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _VolumeSlider(
                    label: 'Music',
                    value: _music,
                    onChanged: (v) => setState(() => _music = v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _VolumeSlider(
                    label: 'Effects',
                    value: _effects,
                    onChanged: (v) => setState(() => _effects = v),
                  ),
                  const SizedBox(height: 48),
                  _MenuButton(label: 'Back', onTap: _onBack),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 52,
      child: active
          ? ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.button(color: AppColors.bg).copyWith(
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
            )
          : OutlinedButton(
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
                  fontSize: 18,
                  letterSpacing: 2,
                ),
              ),
            ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: AppTextStyles.body(color: AppColors.textHigh),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 1,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.secondary,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${(value * 100).round()}%',
            style: AppTextStyles.caption(color: AppColors.textMuted),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

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

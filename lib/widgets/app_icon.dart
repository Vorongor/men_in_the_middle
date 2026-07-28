import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/constants.dart';

/// The catalog families that can carry an `icon_key`. Each one has a Material
/// fallback glyph so a missing or misspelled key never leaves a blank hole in
/// a list — see docs/design/icon_presets.md.
enum AppIconKind {
  software(Icons.terminal),
  hardware(Icons.memory_outlined),
  target(Icons.gps_fixed),
  mission(Icons.assignment_outlined),
  generic(Icons.help_outline);

  const AppIconKind(this.fallbackGlyph);

  final IconData fallbackGlyph;
}

/// Renders a catalog icon resolved from an `icon_key`, following the fallback
/// chain from step 06: item's own key → its kind's default glyph.
///
/// The chain is resolved at paint time via [Image.errorBuilder], so a key that
/// points at a file which is not (yet) bundled degrades to the glyph instead of
/// throwing. That keeps the JSON catalogs editable ahead of the artwork.
class AppIcon extends StatelessWidget {
  const AppIcon({
    super.key,
    required this.iconKey,
    this.kind = AppIconKind.generic,
    this.size = 24,
    this.color,
  });

  /// Catalog `icon_key`. Null or empty goes straight to the [kind] fallback.
  final String? iconKey;
  final AppIconKind kind;
  final double size;

  /// Optional palette tint. Left null the artwork renders with its own colours
  /// — passing a colour flattens the PNG to that single tone, so only do it for
  /// single-tone glyph art. The fallback icon is always tinted.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final key = iconKey?.trim();

    if (key == null || key.isEmpty) return _glyph();

    return Image.asset(
      AppImages.catalogIcon(key),
      width: size,
      height: size,
      color: color,
      filterQuality: FilterQuality.none, // keep the pixel-art edges crisp
      errorBuilder: (_, _, _) => _glyph(),
    );
  }

  Widget _glyph() => Icon(
    kind.fallbackGlyph,
    size: size,
    color: color ?? AppColors.secondary,
  );
}

/// A bundled PNG used as a UI affordance (back arrow, settings cog, hub tile).
/// Unlike [AppIcon] these are known-present assets referenced through
/// [AppImages], so there is no key-resolution or fallback step.
class AppImageIcon extends StatelessWidget {
  const AppImageIcon(this.asset, {super.key, this.size = 24, this.color});

  final String asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      color: color,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) =>
          Icon(Icons.broken_image_outlined, size: size, color: color),
    );
  }
}

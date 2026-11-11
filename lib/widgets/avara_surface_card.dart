import 'package:avara_astrology_trial/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A flat (zero-elevation) pastel surface card used across AVARA screens —
/// e.g. the "Take a moment for yourself" card, habit trackers and AI
/// explanation cards.
///
/// Defaults to a white surface with a hairline [AppColors.border]. Pass a
/// pastel [backgroundColor] (such as [AppColors.lavender]) and an optional
/// [borderColor] (use `null` for a borderless card) to tint the card per its
/// context. Set [onTap] to make the card tappable.
class AvaraSurfaceCard extends StatelessWidget {
  const AvaraSurfaceCard({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.white,
    this.borderColor = AppColors.border,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  /// Card content.
  final Widget child;

  /// Card fill color. Defaults to [AppColors.white]; use a pastel such as
  /// [AppColors.lavender] for tinted cards.
  final Color backgroundColor;

  /// Hairline border color. Set to `null` for a borderless card.
  final Color? borderColor;

  /// Corner radius. Defaults to 16.
  final double borderRadius;

  /// Internal padding. Defaults to 16 on all sides.
  final EdgeInsetsGeometry padding;

  /// Optional tap handler — when non-null the card becomes tappable with a
  /// clipped ripple.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final border = borderColor == null ? null : Border.all(color: borderColor!);
    final content = Padding(padding: padding, child: child);
    final decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: radius,
      border: border,
    );

    // Non-tappable: a single flat decorated box (zero elevation).
    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    // Tappable: paint the surface, then lay a transparent ink layer on top so
    // the InkWell ripple shows through above the fill but beneath the content.
    return DecoratedBox(
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      ),
    );
  }
}

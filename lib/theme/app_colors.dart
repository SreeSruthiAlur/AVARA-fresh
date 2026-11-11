import 'package:flutter/material.dart';

/// AVARA brand color palette.
///
/// Extracted from the brand identity document and grouped into:
/// - [Primary] ramp: the core brand colors (navy → indigo → blue → violet →
///   purple → magenta).
/// - [Secondary]: accent colors used across feature modules.
/// - [Surface]: backgrounds, pastel card fills, borders and muted text.
///
/// Every value is fully opaque (0xFF) so it can be used directly as a [Color].
class AppColors {
  AppColors._();

  // --- Primary --------------------------------------------------------------
  /// Deep navy — app bar, primary text and primary buttons. (#100960)
  static const Color deepNavy = Color(0xFF100960);

  /// Indigo. (#282292)
  static const Color indigo = Color(0xFF282292);

  /// Blue — interactive elements and selection. (#2E71DB)
  static const Color blue = Color(0xFF2E71DB);

  /// Violet. (#831BC8)
  static const Color violet = Color(0xFF831BC8);

  /// Bright purple. (#D04FF5)
  static const Color brightPurple = Color(0xFFD04FF5);

  /// Magenta. (#F87BFB)
  static const Color magenta = Color(0xFFF87BFB);

  // --- Secondary ------------------------------------------------------------
  /// Purple. (#6A54BE)
  static const Color purple = Color(0xFF6A54BE);

  /// Secondary blue (distinct from primary [blue]). (#1B84D4)
  static const Color secondaryBlue = Color(0xFF1B84D4);

  /// Green. (#20AD82)
  static const Color green = Color(0xFF20AD82);

  /// Orange. (#F28D2D)
  static const Color orange = Color(0xFFF28D2D);

  /// Magenta-purple. (#A348B9)
  static const Color magentaPurple = Color(0xFFA348B9);

  /// Teal-blue. (#168BAE)
  static const Color tealBlue = Color(0xFF168BAE);

  // --- Surface --------------------------------------------------------------
  /// Background — scaffold base. (#F9FBFC)
  static const Color background = Color(0xFFF9FBFC);

  /// White — card / sheet surface. (#FFFFFF)
  static const Color white = Color(0xFFFFFFFF);

  /// Lavender — pastel card fill. (#F1EFFD)
  static const Color lavender = Color(0xFFF1EFFD);

  /// Light blue — pastel card fill. (#E5F2FE)
  static const Color lightBlue = Color(0xFFE5F2FE);

  /// Light cyan — pastel card fill. (#E5F8FC)
  static const Color lightCyan = Color(0xFFE5F8FC);

  /// Light green — pastel card fill. (#E6F8F0)
  static const Color lightGreen = Color(0xFFE6F8F0);

  /// Light orange — pastel card fill. (#FEF2E6)
  static const Color lightOrange = Color(0xFFFEF2E6);

  /// Light pink — pastel card fill. (#FBEAFC)
  static const Color lightPink = Color(0xFFFBEAFC);

  /// Border — hairline for cards / inputs. (#DCE5F2)
  static const Color border = Color(0xFFDCE5F2);

  /// Secondary text — captions / muted labels. (#52617A)
  static const Color secondaryText = Color(0xFF52617A);
}

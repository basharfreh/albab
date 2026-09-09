import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Cairo, weights 400/600/700 only (brief §9). Bundled as an asset — never fetched at
/// runtime. Scale: display 24/700, title 20/700, section 16/600, body 14/400, label
/// 13/600, caption 12/400 — line height 1.5 on body text specifically (long-form Arabic
/// reading copy), left at the font's natural metrics everywhere else.
abstract final class AppTypography {
  static const _fontFamily = 'Cairo';

  static const display = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const section = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}

import 'package:flutter/widgets.dart';

/// Fixed design-token colors from the approved mockup (brief §9). Do not add a color that
/// isn't listed here — derive any new state from these instead.
abstract final class AppColors {
  static const primary = Color(0xFF1B8B4C);
  static const primaryDark = Color(0xFF0F6B39);
  static const primaryTint = Color(0xFFE8F5EE);
  static const navy = Color(0xFF1B2A41);
  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF4F6F8);
  static const border = Color(0xFFE4E7EB);
  static const textPrimary = Color(0xFF1A1D22);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9AA1AC);
  static const danger = Color(0xFFE14B4B);
  static const warning = Color(0xFFF0A030);
}

/// Map-pin / by-type-pie colors — the map legend and the admin pie chart must agree on this.
abstract final class AppPropertyTypeColors {
  static const house = Color(0xFF1B8B4C);
  static const apartment = Color(0xFFF0A030);
  static const shop = Color(0xFF3B82F6);
  static const land = Color(0xFF8B5CF6);
  static const other = Color(0xFF6B7280);
}

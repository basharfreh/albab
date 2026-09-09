import 'package:flutter/widgets.dart';

/// Corner radii (brief §9): 16 for cards/sheets, 12 for buttons/inputs, 999 (pill) for
/// chips and the FAB.
abstract final class AppRadius {
  static const card = 16.0;
  static const button = 12.0;
  static const pill = 999.0;

  static const cardRadius = BorderRadius.all(Radius.circular(card));
  static const buttonRadius = BorderRadius.all(Radius.circular(button));
  static const pillRadius = BorderRadius.all(Radius.circular(pill));
}

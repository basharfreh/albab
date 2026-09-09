import 'package:flutter/widgets.dart';

/// The one shadow the whole app uses (brief §9: "Nothing else casts a shadow"):
/// `0 2 8 rgba(16,24,40,0.06)`. Cards get it cast downward; bottom sheets get it
/// inverted upward (the sheet floats above content, not below it).
abstract final class AppShadows {
  static const _color = Color.fromRGBO(16, 24, 40, 0.06);

  static const card = [
    BoxShadow(color: _color, offset: Offset(0, 2), blurRadius: 8),
  ];

  static const sheet = [
    BoxShadow(color: _color, offset: Offset(0, -2), blurRadius: 8),
  ];
}

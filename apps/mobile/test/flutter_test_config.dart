import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads real fonts before any test runs, so golden images render actual glyphs instead of
/// `flutter_test`'s fallback tofu/placeholder boxes — without this, every golden captured on
/// this machine would be meaningless (and would drift the moment a real font happened to be
/// loadable on some other machine/CI runner). Two fonts are needed: Cairo (the app's own text)
/// and Material Icons (every `Icon` widget is just a glyph in that font).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFont('Cairo', 'packages/albab_core/fonts/Cairo-Variable.ttf');
  await _loadFont('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
  await testMain();
}

Future<void> _loadFont(String family, String assetKey) async {
  final data = await rootBundle.load(assetKey);
  await (FontLoader(family)..addFont(Future.value(data))).load();
}

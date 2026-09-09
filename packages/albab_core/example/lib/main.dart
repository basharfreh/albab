import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgetbook_page.dart';

void main() {
  runApp(const ProviderScope(child: GalleryApp()));
}

class GalleryApp extends ConsumerWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'albab_core widget gallery',
      theme: AppTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const WidgetbookPage(),
    );
  }
}

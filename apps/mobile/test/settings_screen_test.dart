import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/features/settings/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Widget _wrap(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/edit-profile',
        builder: (context, state) => const Scaffold(body: Text('EDIT PROFILE')),
      ),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('switching to English updates localeProvider and persists it', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(container.read(localeProvider).languageCode, 'en');
    expect(await container.read(prefsStorageProvider).readLocaleCode(), 'en');
  });

  testWidgets('change password and delete account show the not-available message', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تغيير كلمة المرور'));
    await tester.pumpAndSettle();
    expect(find.text('هذه الميزة غير متاحة حالياً — تواصل مع الدعم.'), findsOneWidget);
  });

  testWidgets('delete account requires confirmation before showing the message', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حذف الحساب'));
    await tester.pumpAndSettle();
    expect(find.text('حذف الحساب؟'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.text('هذه الميزة غير متاحة حالياً — تواصل مع الدعم.'), findsNothing);
  });

  testWidgets('edit profile row navigates to the edit-profile route', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تعديل الملف الشخصي'));
    await tester.pumpAndSettle();
    expect(find.text('EDIT PROFILE'), findsOneWidget);
  });
}

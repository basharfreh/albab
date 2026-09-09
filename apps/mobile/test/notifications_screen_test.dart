import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/features/notifications/data/notifications_repository.dart';
import 'package:albab_mobile/features/notifications/ui/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeNotificationsRepository extends NotificationsRepository {
  _FakeNotificationsRepository(super.ref);

  List<AppNotification> items = const [];
  final markedRead = <int>[];
  bool markedAllRead = false;

  @override
  Future<List<AppNotification>> fetchNotifications() async => items;

  @override
  Future<void> markRead(int notificationId) async {
    markedRead.add(notificationId);
  }

  @override
  Future<void> markAllRead() async {
    markedAllRead = true;
  }
}

Widget _wrap(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) =>
            Scaffold(body: Text('LISTING ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/conversation/:id',
        builder: (context, state) =>
            Scaffold(body: Text('CONVERSATION ${state.pathParameters['id']}')),
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
  late _FakeNotificationsRepository repo;

  ProviderContainer buildContainer({List<AppNotification> items = const []}) {
    final container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWith((ref) {
          repo = _FakeNotificationsRepository(ref)..items = items;
          return repo;
        }),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  testWidgets('tapping an unread notification marks it read and routes by kind', (tester) async {
    final container = buildContainer(
      items: [
        AppNotification(
          id: 1,
          kind: 'listing_approved',
          title: 'تمت الموافقة على عقارك',
          data: const {'listing_id': 42},
          createdAt: DateTime.now(),
        ),
      ],
    );
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('اليوم'), findsOneWidget);
    await tester.tap(find.text('تمت الموافقة على عقارك'));
    await tester.pumpAndSettle();

    expect(repo.markedRead, [1]);
    expect(find.text('LISTING 42'), findsOneWidget);
  });

  testWidgets('a new_message notification routes to the conversation', (tester) async {
    final container = buildContainer(
      items: [
        AppNotification(
          id: 2,
          kind: 'new_message',
          title: 'رسالة جديدة',
          data: const {'conversation_id': 7, 'listing_id': 9},
          createdAt: DateTime.now(),
        ),
      ],
    );
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.text('رسالة جديدة'));
    await tester.pumpAndSettle();

    expect(find.text('CONVERSATION 7'), findsOneWidget);
  });

  testWidgets('mark-all-read appears only with unread items and clears them', (tester) async {
    final container = buildContainer(
      items: [
        AppNotification(
          id: 3,
          kind: 'listing_rejected',
          title: 'تم رفض عقارك',
          data: const {'listing_id': 1},
          createdAt: DateTime.now(),
        ),
      ],
    );
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('تعليم الكل كمقروء'), findsOneWidget);
    await tester.tap(find.text('تعليم الكل كمقروء'));
    await tester.pumpAndSettle();

    expect(repo.markedAllRead, isTrue);
    expect(find.text('تعليم الكل كمقروء'), findsNothing);
  });

  testWidgets('shows the empty state when there are no notifications', (tester) async {
    final container = buildContainer();
    await tester.pumpWidget(_wrap(container));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد إشعارات'), findsOneWidget);
    expect(find.text('تعليم الكل كمقروء'), findsNothing);
  });
}

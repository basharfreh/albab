import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/features/listing_detail/data/listing_detail_repository.dart';
import 'package:albab_mobile/features/listing_detail/ui/listing_detail_screen.dart';
import 'package:albab_mobile/features/map/data/listings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Same "record what was requested, return canned data" pattern the map/filter tests use —
/// see `map_home_screen_test.dart`'s `_FakeListingsRepository`.
class _FakeListingsRepository extends ListingsRepository {
  _FakeListingsRepository(super.ref);

  Listing? detail;
  final events = <(int, ListingEventKind)>[];

  @override
  Future<Listing> fetchListingDetail(int id) async {
    final found = detail;
    if (found == null) throw StateError('no detail stubbed');
    return found;
  }

  @override
  Future<void> postEvent(int listingId, ListingEventKind kind) async {
    events.add((listingId, kind));
  }
}

class _FakeListingDetailRepository extends ListingDetailRepository {
  _FakeListingDetailRepository(super.ref);

  List<Listing> similar = const [];
  final favoriteCalls = <(int, bool)>[];
  bool failFavoriteCalls = false;
  String? reportedReason;
  String? reportedNote;

  @override
  Future<List<Listing>> fetchSimilar(Listing listing) async => similar;

  @override
  Future<void> addFavorite(int listingId) async {
    if (failFavoriteCalls) throw const ApiException(kind: ApiErrorKind.unknown);
    favoriteCalls.add((listingId, true));
  }

  @override
  Future<void> removeFavorite(int listingId) async {
    if (failFavoriteCalls) throw const ApiException(kind: ApiErrorKind.unknown);
    favoriteCalls.add((listingId, false));
  }

  @override
  Future<void> report(int listingId, {required String reason, String? note}) async {
    reportedReason = reason;
    reportedNote = note;
  }
}

class _FakeAuthNotifier extends AuthStateNotifier {
  _FakeAuthNotifier(this._initial);
  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

final _owner = User(
  id: 5,
  name: 'محمد العلي',
  role: UserRole.owner,
  phone: '+963987654321',
  whatsappPhone: '+963987654321',
  createdAt: DateTime.utc(2024, 3, 1),
);

final _listing = Listing(
  id: 101,
  title: 'شقة في حي الحسين',
  purpose: ListingPurpose.sale,
  propertyType: PropertyType.apartment,
  price: '85000.00',
  neighborhoodName: 'حي الحسين',
  landmark: 'قرب جامع النور',
  imagesCount: 0,
  images: const [],
  description: 'شقة واسعة ومضيئة.',
  owner: _owner,
);

const _similarListing = Listing(
  id: 202,
  title: 'منزل في حي الزهراء',
  purpose: ListingPurpose.sale,
  propertyType: PropertyType.house,
  price: '90000.00',
  neighborhoodName: 'حي الزهراء',
  imagesCount: 0,
);

Widget _appWithDetailRoute(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/listing/101',
    routes: [
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) =>
            ListingDetailScreen(listingId: int.parse(state.pathParameters['id']!)),
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
  late _FakeListingsRepository listingsRepo;
  late _FakeListingDetailRepository detailRepo;
  late ProviderContainer container;

  ProviderContainer buildContainer(AuthState authState, {List<Listing> similar = const []}) {
    return ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(() => _FakeAuthNotifier(authState)),
        listingsRepositoryProvider.overrideWith((ref) {
          listingsRepo = _FakeListingsRepository(ref)..detail = _listing;
          return listingsRepo;
        }),
        listingDetailRepositoryProvider.overrideWith((ref) {
          detailRepo = _FakeListingDetailRepository(ref)..similar = similar;
          return detailRepo;
        }),
      ],
    );
  }

  setUp(() {
    container = buildContainer(AuthState.authenticated(_owner));
    addTearDown(container.dispose);
  });

  testWidgets('shows listing detail and fires exactly one view event', (tester) async {
    await tester.pumpWidget(_appWithDetailRoute(container));
    await tester.pumpAndSettle();

    expect(find.text('شقة في حي الحسين'), findsOneWidget);
    expect(find.text('\$85,000'), findsOneWidget);
    expect(listingsRepo.events, [(101, ListingEventKind.view)]);
  });

  testWidgets('an authenticated user can toggle favorite, calling add then remove', (
    tester,
  ) async {
    await tester.pumpWidget(_appWithDetailRoute(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(detailRepo.favoriteCalls, [(101, true)]);
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();
    expect(detailRepo.favoriteCalls, [(101, true), (101, false)]);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('a favorite call that fails rolls the icon back', (tester) async {
    container = buildContainer(AuthState.authenticated(_owner));
    await tester.pumpWidget(_appWithDetailRoute(container));
    await tester.pumpAndSettle();
    detailRepo.failFavoriteCalls = true;

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    expect(detailRepo.favoriteCalls, isEmpty);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('a guest tapping favorite sees the guest-gate sheet, not an API call', (
    tester,
  ) async {
    container = buildContainer(const AuthState.guest());
    await tester.pumpWidget(_appWithDetailRoute(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    expect(detailRepo.favoriteCalls, isEmpty);
    expect(find.text('سجّل الدخول للمتابعة'), findsOneWidget);
  });

  testWidgets('reporting submits the chosen reason and shows a confirmation snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(_appWithDetailRoute(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإبلاغ عن هذا العقار'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('عملية احتيال'));
    await tester.tap(find.text('إرسال البلاغ'));
    await tester.pumpAndSettle();

    expect(detailRepo.reportedReason, 'fraud');
    expect(find.text('تم إرسال البلاغ.'), findsOneWidget);
  });

  testWidgets('a guest opening the report menu sees the guest-gate sheet', (tester) async {
    container = buildContainer(const AuthState.guest());
    await tester.pumpWidget(_appWithDetailRoute(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإبلاغ عن هذا العقار'));
    await tester.pumpAndSettle();

    expect(find.text('سجّل الدخول للمتابعة'), findsOneWidget);
    expect(find.text('سبب البلاغ'), findsNothing); // the report sheet never opened
  });

  testWidgets('renders the similar-listings strip and opening one fires its own view event', (
    tester,
  ) async {
    container = buildContainer(
      AuthState.authenticated(_owner),
      similar: [_similarListing],
    );
    await tester.pumpWidget(_appWithDetailRoute(container));
    await tester.pumpAndSettle();

    expect(find.text('عقارات مشابهة'), findsOneWidget);
    expect(find.text('منزل في حي الزهراء'), findsOneWidget);

    await tester.ensureVisible(find.text('منزل في حي الزهراء'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('منزل في حي الزهراء'));
    await tester.pumpAndSettle();

    expect(listingsRepo.events, contains((202, ListingEventKind.view)));
  });
}

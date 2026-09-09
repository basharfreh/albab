import 'package:albab_core/albab_core.dart';
import 'package:albab_mobile/features/add_listing/data/add_listing_repository.dart';
import 'package:albab_mobile/features/add_listing/data/image_picker_service.dart';
import 'package:albab_mobile/features/add_listing/data/wizard_draft.dart';
import 'package:albab_mobile/features/add_listing/ui/add_listing_wizard_screen.dart';
import 'package:albab_mobile/features/map/data/listings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// A fake path is enough — [Step3Photos]'s thumbnail preview (`_PhotoThumbnail`) falls back
/// to a plain placeholder when `Image.file` can't decode it (see that widget's own
/// `errorBuilder`), so this never needs to touch real disk to behave like a picked file.
class _FakeImagePickerService implements ImagePickerService {
  int _counter = 0;

  PickedImage _next() {
    final n = _counter++;
    return PickedImage(path: '/fake/pick_$n.png', name: 'pick_$n.png');
  }

  @override
  Future<List<PickedImage>> pickFromGallery({
    required int remainingSlots,
  }) async => [_next()];

  @override
  Future<PickedImage?> pickFromCamera() async => _next();
}

/// Records every call the wizard makes and returns canned/deterministic responses — same
/// "fake repository" pattern every prior mobile test file uses (see
/// `listing_detail_screen_test.dart`'s `_FakeListingsRepository`).
class _FakeAddListingRepository extends AddListingRepository {
  _FakeAddListingRepository(super.ref);

  int nextId = 900;
  final createdDrafts = <Map<String, dynamic>>[];
  final patches = <(int, Map<String, dynamic>)>[];
  final uploads = <String>[];
  final deletes = <int>[];
  final reorders = <List<int>>[];
  final submits = <int>[];

  Neighborhood? reverseResult = const Neighborhood(
    id: 1,
    nameAr: 'حي الحسين',
    nameEn: 'Al-Hussein',
    slug: 'al-hussein',
    centerLat: '36.37',
    centerLng: '37.52',
  );

  /// When set, [submit] throws this instead of succeeding.
  ApiException? submitError;
  Listing? resumeListing;

  @override
  Future<Listing> createDraft(WizardDraft draft) async {
    createdDrafts.add({'title': draft.title, 'price': draft.price});
    final id = nextId++;
    return Listing(
      id: id,
      title: draft.title,
      purpose: draft.purpose,
      propertyType: draft.propertyType,
      price: draft.price,
      bedrooms: draft.bedrooms,
      bathrooms: draft.bathrooms,
      description: draft.description,
      images: const [],
    );
  }

  @override
  Future<Listing> patchStep1(int listingId, WizardDraft draft) async {
    patches.add((listingId, {'step': 1}));
    return createDraft(draft);
  }

  @override
  Future<Listing> patchLocation(int listingId, WizardDraft draft) async {
    patches.add((listingId, {'step': 2}));
    return Listing(
      id: listingId,
      title: draft.title,
      purpose: draft.purpose,
      propertyType: draft.propertyType,
      price: draft.price,
      lat: draft.lat?.toString(),
      lng: draft.lng?.toString(),
    );
  }

  @override
  Future<Listing> fetchListing(int listingId) async {
    final listing = resumeListing;
    if (listing == null) throw StateError('no resume listing stubbed');
    return listing;
  }

  @override
  Future<ListingImage> uploadImage(
    int listingId, {
    required String path,
    required String filename,
    bool isCover = false,
    void Function(double progress)? onProgress,
  }) async {
    uploads.add(path);
    onProgress?.call(1.0);
    return ListingImage(
      id: uploads.length,
      image: 'https://cdn.example/$filename',
      thumbnail: 'https://cdn.example/thumb_$filename',
      sortOrder: uploads.length - 1,
      isCover: isCover || uploads.length == 1,
    );
  }

  @override
  Future<void> deleteImage(int listingId, int imageId) async {
    deletes.add(imageId);
  }

  @override
  Future<void> reorderImages(int listingId, List<int> order) async {
    reorders.add(order);
  }

  @override
  Future<Listing> submit(int listingId) async {
    submits.add(listingId);
    final error = submitError;
    if (error != null) throw error;
    return Listing(
      id: listingId,
      title: 'x',
      purpose: ListingPurpose.sale,
      propertyType: PropertyType.house,
      status: ListingStatus.pending,
    );
  }

  @override
  Future<Neighborhood?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    return reverseResult;
  }
}

class _FakeListingsRepository extends ListingsRepository {
  _FakeListingsRepository(super.ref);

  @override
  Future<List<Neighborhood>> fetchNeighborhoods() async => const [
    Neighborhood(
      id: 1,
      nameAr: 'حي الحسين',
      nameEn: 'Al-Hussein',
      slug: 'al-hussein',
      centerLat: '36.37',
      centerLng: '37.52',
    ),
  ];
}

Widget _wrap(ProviderContainer container) {
  final router = GoRouter(
    initialLocation: '/add',
    routes: [
      GoRoute(
        path: '/add',
        builder: (context, state) => const AddListingWizardScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const Scaffold(body: Text('MAP')),
      ),
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) =>
            Scaffold(body: Text('LISTING ${state.pathParameters['id']}')),
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
  late _FakeAddListingRepository repo;
  late ProviderContainer container;

  ProviderContainer buildContainer({Listing? resumeListing}) {
    final container = ProviderContainer(
      overrides: [
        addListingRepositoryProvider.overrideWith((ref) {
          repo = _FakeAddListingRepository(ref)..resumeListing = resumeListing;
          return repo;
        }),
        listingsRepositoryProvider.overrideWith(
          (ref) => _FakeListingsRepository(ref),
        ),
        imagePickerServiceProvider.overrideWith(
          (ref) => _FakeImagePickerService(),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    container = buildContainer();
  });

  Future<void> fillStep1(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'عنوان الإعلان'),
      'منزل جميل',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'السعر'),
      '50000',
    );
    await tester.tap(find.text('التالي'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> confirmLocation(WidgetTester tester) async {
    await tester.tap(find.text('تأكيد الموقع'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('التالي'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> addOnePhoto(WidgetTester tester) async {
    await tester.tap(find.byTooltip('اختر من المعرض'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets(
    'completing all four steps creates a draft, uploads a photo, and submits',
    (tester) async {
      await tester.pumpWidget(_wrap(container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await fillStep1(tester);
      expect(repo.createdDrafts, hasLength(1));
      expect(find.text('تأكيد الموقع'), findsOneWidget);

      await confirmLocation(tester);
      expect(
        find.text('إضافة صور', skipOffstage: false),
        findsNothing,
      ); // sanity: no stray copy
      expect(find.byTooltip('اختر من المعرض'), findsOneWidget);

      await addOnePhoto(tester);
      expect(repo.uploads, hasLength(1));

      await tester.tap(find.text('التالي'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.text('مراجعة'),
        findsWidgets,
      ); // step header label + review content present
      expect(find.text('منزل جميل'), findsWidgets);

      await tester.tap(find.text('نشر العقار'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(repo.submits, [repo.nextId - 1]);
      expect(find.text('تم إرسال عقارك للمراجعة'), findsOneWidget);
    },
  );

  testWidgets('step 1 blocks advancing until title and price are filled', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('التالي'));
    await tester.pump();

    expect(repo.createdDrafts, isEmpty);
    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
  });

  testWidgets('a quota rejection at submit shows the friendly quota screen', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await fillStep1(tester);
    await confirmLocation(tester);
    await addOnePhoto(tester);
    await tester.tap(find.text('التالي'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    repo.submitError = const ApiException(
      kind: ApiErrorKind.server,
      message: 'لقد وصلت إلى الحد الأقصى لعدد العقارات النشطة (10).',
    );
    await tester.tap(find.text('نشر العقار'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('وصلت إلى الحد الأقصى'), findsOneWidget);
    expect(
      find.text('لقد وصلت إلى الحد الأقصى لعدد العقارات النشطة (10).'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a missing-image field error at submit jumps back to the photos step',
    (tester) async {
      await tester.pumpWidget(_wrap(container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await fillStep1(tester);
      await confirmLocation(tester);
      await addOnePhoto(tester);
      await tester.tap(find.text('التالي'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      repo.submitError = const ApiException(
        kind: ApiErrorKind.server,
        fieldErrors: {
          'images': ['أضف صورة واحدة على الأقل.'],
        },
      );
      await tester.tap(find.text('نشر العقار'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Back on step 3 (photos) rather than the success/quota screen.
      expect(find.byTooltip('اختر من المعرض'), findsOneWidget);
      expect(find.text('تم إرسال عقارك للمراجعة'), findsNothing);
    },
  );

  testWidgets('a remembered draft id resumes the wizard at the saved step', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
          'albab_wizard_draft_id': 777,
          'albab_wizard_step': 2,
        });
    container = buildContainer(
      resumeListing: const Listing(
        id: 777,
        title: 'شقة قديمة محفوظة',
        purpose: ListingPurpose.rent,
        propertyType: PropertyType.apartment,
        price: '30000.00',
        lat: '36.37',
        lng: '37.52',
        neighborhoodName: 'حي الحسين',
        images: [],
      ),
    );

    await tester.pumpWidget(_wrap(container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Resumed straight onto step 3 (photos, index 2) with step 1's data already hydrated.
    expect(find.byTooltip('اختر من المعرض'), findsOneWidget);
    await addOnePhoto(tester);
    await tester.tap(find.text('التالي'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('شقة قديمة محفوظة'), findsWidgets);
  });
}

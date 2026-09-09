import 'package:albab_core/albab_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'wizard_draft.dart';

/// Everything UC-30…UC-34/UC-38 need from `/listings/*` and `/geo/reverse/` — draft
/// create/patch, image upload/delete/reorder, submit. Calls `dio` directly, same
/// feature-owns-its-data pattern every prior mobile repository set (`AuthRepository`,
/// `ListingsRepository`, `ListingDetailRepository`, `GeoRepository`).
class AddListingRepository {
  AddListingRepository(this._ref);

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  Map<String, dynamic> _step1Fields(WizardDraft draft) => {
    'title': draft.title.trim(),
    'property_type': draft.propertyType.wireValue,
    'purpose': draft.purpose.wireValue,
    'price': draft.price,
    'is_negotiable': draft.isNegotiable,
    'bedrooms': draft.bedrooms,
    'bathrooms': draft.bathrooms,
    'description': draft.description.trim(),
  };

  /// `POST /listings/` — brief P9 item 6: written once step 1 validates, so every image
  /// upload from step 3 onward has a real listing id to attach to.
  Future<Listing> createDraft(WizardDraft draft) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/listings/',
        data: _step1Fields(draft),
      );
      return Listing.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<Listing> patchStep1(int listingId, WizardDraft draft) async {
    return _patch(listingId, _step1Fields(draft));
  }

  Future<Listing> patchLocation(int listingId, WizardDraft draft) async {
    return _patch(listingId, {
      'lat': draft.lat,
      'lng': draft.lng,
      if (draft.neighborhoodId != null) 'neighborhood': draft.neighborhoodId,
      'landmark': draft.landmark.trim(),
    });
  }

  Future<Listing> _patch(int listingId, Map<String, dynamic> fields) async {
    try {
      final response = await _api.dio.patch<Map<String, dynamic>>(
        '/listings/$listingId/',
        data: fields,
      );
      return Listing.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<Listing> fetchListing(int listingId) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/listings/$listingId/',
      );
      return Listing.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// Brief P9 item 4: per-image upload progress, retry on failure. [onProgress] reports
  /// 0.0–1.0.
  Future<ListingImage> uploadImage(
    int listingId, {
    required String path,
    required String filename,
    bool isCover = false,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(path, filename: filename),
        if (isCover) 'is_cover': 'true',
      });
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/listings/$listingId/images/',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );
      return ListingImage.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<void> deleteImage(int listingId, int imageId) async {
    try {
      await _api.dio.delete<void>('/listings/$listingId/images/$imageId/');
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  Future<void> reorderImages(int listingId, List<int> order) async {
    try {
      await _api.dio.post<void>(
        '/listings/$listingId/images/reorder/',
        data: {'order': order},
      );
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// "تعيين كصورة رئيسية" (brief P9 item 4) has no dedicated backend endpoint — flagged as a
  /// real gap by P2 for whichever phase needed it, with "handle it via reorder+re-upload"
  /// suggested as the fallback. Implemented exactly that way: delete the old server row for
  /// this image, then re-upload the same local bytes with `is_cover: true` (which, per
  /// `ListingImageListCreateView.create()`, unsets `is_cover` on every other image of this
  /// listing server-side) — only possible for an image whose [WizardImageEntry.localPath]
  /// is still available on this device (see that class's own doc comment on why).
  Future<ListingImage> setCoverPhoto(
    int listingId,
    WizardImageEntry entry,
  ) async {
    final path = entry.localPath;
    final remoteId = entry.remoteId;
    if (path == null || remoteId == null) {
      throw StateError(
        'setCoverPhoto needs both a local file and an uploaded image.',
      );
    }
    await deleteImage(listingId, remoteId);
    return uploadImage(
      listingId,
      path: path,
      filename: path.split('/').last,
      isCover: true,
    );
  }

  /// `POST /listings/{id}/submit/` — draft/rejected → pending. Throws [ApiException] with
  /// `fieldErrors` (`images`/`price`/`location`/`neighborhood`) when required data is
  /// missing, or a plain `message` (no `fieldErrors`) for the Arabic quota-exceeded text —
  /// callers distinguish the two (brief P9 item 7's "friendly quota screen" vs. jumping back
  /// to the offending step) by checking `fieldErrors.isEmpty`.
  Future<Listing> submit(int listingId) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/listings/$listingId/submit/',
      );
      return Listing.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }

  /// `GET /geo/reverse/?lat=&lng=` — fills the neighborhood from the confirmed map point
  /// (brief P9 item 3). `204` (no nearby neighborhood) surfaces as `null`, not an error.
  Future<Neighborhood?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/geo/reverse/',
        queryParameters: {'lat': lat, 'lng': lng},
      );
      if (response.statusCode == 204 || response.data == null) return null;
      return Neighborhood.fromJson(response.data!);
    } on DioException catch (e) {
      throw _api.mapError(e);
    }
  }
}

final addListingRepositoryProvider = Provider<AddListingRepository>(
  (ref) => AddListingRepository(ref),
);

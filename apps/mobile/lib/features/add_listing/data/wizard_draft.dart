import 'package:albab_core/albab_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One photo in the wizard's step-3 list — either a locally-picked file still uploading (or
/// queued to), or an already-uploaded [ListingImage]. [localPath] and [remoteId] are both
/// non-null right after a successful upload (kept together so "تعيين كصورة رئيسية" — see
/// [AddListingRepository.setCoverPhoto] — can re-upload the same bytes; a resumed session
/// that only fetched the listing from the server has [localPath] == null and that action is
/// unavailable for it, since the original file no longer exists on this device).
class WizardImageEntry {
  const WizardImageEntry({
    this.localPath,
    this.remoteId,
    this.thumbnailUrl,
    this.isCover = false,
    this.uploading = false,
    this.progress = 0,
    this.error,
  });

  final String? localPath;
  final int? remoteId;
  final String? thumbnailUrl;
  final bool isCover;
  final bool uploading;
  final double progress;
  final String? error;

  bool get isUploaded => remoteId != null;

  WizardImageEntry copyWith({
    int? Function()? remoteId,
    String? Function()? thumbnailUrl,
    bool? isCover,
    bool? uploading,
    double? progress,
    String? Function()? error,
  }) {
    return WizardImageEntry(
      localPath: localPath,
      remoteId: remoteId == null ? this.remoteId : remoteId(),
      thumbnailUrl: thumbnailUrl == null ? this.thumbnailUrl : thumbnailUrl(),
      isCover: isCover ?? this.isCover,
      uploading: uploading ?? this.uploading,
      progress: progress ?? this.progress,
      error: error == null ? this.error : error(),
    );
  }

  factory WizardImageEntry.fromListingImage(ListingImage image) {
    return WizardImageEntry(
      remoteId: image.id,
      thumbnailUrl: image.thumbnail ?? image.image,
      isCover: image.isCover,
    );
  }
}

/// The wizard's working state — brief P9's four steps (المعلومات → الموقع → الصور →
/// مراجعة), UC-30…UC-34. Hand-written, not `@freezed`, matching `MapFilters`'/P6's own
/// reasoning: `apps/mobile` has no codegen step, and this class's `copyWith` is small enough
/// to hand-roll.
///
/// [listingId] is null until step 1's "التالي" creates the real `draft` listing server-side
/// (brief item 6) — every field before that only exists in memory; every field after it is
/// PATCHed to the server as it changes, so an interrupted session can always resume from
/// `GET /listings/{id}/` plus the locally-remembered step (`PrefsStorage`).
class WizardDraft {
  const WizardDraft({
    this.listingId,
    this.title = '',
    this.propertyType = PropertyType.house,
    this.purpose = ListingPurpose.sale,
    this.price,
    this.isNegotiable = false,
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.description = '',
    this.lat,
    this.lng,
    this.neighborhoodId,
    this.neighborhoodNameAr,
    this.landmark = '',
    this.images = const [],
    this.step = 0,
  });

  final int? listingId;
  final String title;
  final PropertyType propertyType;
  final ListingPurpose purpose;

  /// Plain digits, no thousands separators (the UI field formats those for display only).
  final String? price;
  final bool isNegotiable;
  final int bedrooms;
  final int bathrooms;
  final String description;
  final double? lat;
  final double? lng;
  final int? neighborhoodId;
  final String? neighborhoodNameAr;
  final String landmark;
  final List<WizardImageEntry> images;
  final int step;

  bool get hasLocation => lat != null && lng != null;

  bool get step1Valid =>
      title.trim().isNotEmpty && (num.tryParse(price ?? '') ?? 0) > 0;

  WizardDraft copyWith({
    int? Function()? listingId,
    String? title,
    PropertyType? propertyType,
    ListingPurpose? purpose,
    String? Function()? price,
    bool? isNegotiable,
    int? bedrooms,
    int? bathrooms,
    String? description,
    double? Function()? lat,
    double? Function()? lng,
    int? Function()? neighborhoodId,
    String? Function()? neighborhoodNameAr,
    String? landmark,
    List<WizardImageEntry>? images,
    int? step,
  }) {
    return WizardDraft(
      listingId: listingId == null ? this.listingId : listingId(),
      title: title ?? this.title,
      propertyType: propertyType ?? this.propertyType,
      purpose: purpose ?? this.purpose,
      price: price == null ? this.price : price(),
      isNegotiable: isNegotiable ?? this.isNegotiable,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      description: description ?? this.description,
      lat: lat == null ? this.lat : lat(),
      lng: lng == null ? this.lng : lng(),
      neighborhoodId: neighborhoodId == null
          ? this.neighborhoodId
          : neighborhoodId(),
      neighborhoodNameAr: neighborhoodNameAr == null
          ? this.neighborhoodNameAr
          : neighborhoodNameAr(),
      landmark: landmark ?? this.landmark,
      images: images ?? this.images,
      step: step ?? this.step,
    );
  }

  /// Hydrates from the server's own shape (a freshly-created draft, or a resumed one) —
  /// everything [ListingDetailSerializer] carries that the wizard also collects. Local-only
  /// wizard state (which step we're on) is not part of this and is set separately from
  /// `PrefsStorage`.
  factory WizardDraft.fromListing(Listing listing) {
    return WizardDraft(
      listingId: listing.id,
      title: listing.title,
      propertyType: listing.propertyType,
      purpose: listing.purpose,
      price: listing.price == null
          ? null
          : num.parse(listing.price!).toStringAsFixed(0),
      isNegotiable: listing.isNegotiable,
      bedrooms: listing.bedrooms ?? 1,
      bathrooms: listing.bathrooms ?? 1,
      description: listing.description ?? '',
      lat: listing.lat == null ? null : double.parse(listing.lat!),
      lng: listing.lng == null ? null : double.parse(listing.lng!),
      neighborhoodNameAr: listing.neighborhoodName,
      landmark: listing.landmark,
      images: (listing.images ?? [])
          .map(WizardImageEntry.fromListingImage)
          .toList(),
    );
  }
}

class WizardNotifier extends Notifier<WizardDraft> {
  @override
  WizardDraft build() => const WizardDraft();

  void reset() => state = const WizardDraft();

  void load(WizardDraft draft) => state = draft;

  void setStep(int step) => state = state.copyWith(step: step);

  void setTitle(String value) => state = state.copyWith(title: value);

  void setPropertyType(PropertyType value) =>
      state = state.copyWith(propertyType: value);

  void setPurpose(ListingPurpose value) =>
      state = state.copyWith(purpose: value);

  void setPrice(String? value) => state = state.copyWith(price: () => value);

  void setNegotiable(bool value) => state = state.copyWith(isNegotiable: value);

  void setBedrooms(int value) => state = state.copyWith(bedrooms: value);

  void setBathrooms(int value) => state = state.copyWith(bathrooms: value);

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  void setListingId(int id) => state = state.copyWith(listingId: () => id);

  void setLocation({
    required double lat,
    required double lng,
    int? neighborhoodId,
    String? neighborhoodNameAr,
  }) {
    state = state.copyWith(
      lat: () => lat,
      lng: () => lng,
      neighborhoodId: () => neighborhoodId,
      neighborhoodNameAr: () => neighborhoodNameAr,
    );
  }

  void setLandmark(String value) => state = state.copyWith(landmark: value);

  void setImages(List<WizardImageEntry> images) =>
      state = state.copyWith(images: images);

  void addImage(WizardImageEntry entry) =>
      state = state.copyWith(images: [...state.images, entry]);

  void updateImageAt(
    int index,
    WizardImageEntry Function(WizardImageEntry) update,
  ) {
    final images = [...state.images];
    images[index] = update(images[index]);
    state = state.copyWith(images: images);
  }

  /// Looked up by [WizardImageEntry.localPath] rather than list index — an in-flight
  /// upload's index can shift out from under it if the user deletes or reorders another
  /// image in the meantime, but the local file path a given upload is for never changes.
  void updateImageByPath(
    String path,
    WizardImageEntry Function(WizardImageEntry) update,
  ) {
    state = state.copyWith(
      images: [
        for (final image in state.images)
          if (image.localPath == path) update(image) else image,
      ],
    );
  }

  void removeImageAt(int index) {
    final images = [...state.images]..removeAt(index);
    state = state.copyWith(images: images);
  }

  void insertImageAt(int index, WizardImageEntry entry) {
    final images = [...state.images]..insert(index, entry);
    state = state.copyWith(images: images);
  }
}

final wizardDraftProvider = NotifierProvider<WizardNotifier, WizardDraft>(
  WizardNotifier.new,
);

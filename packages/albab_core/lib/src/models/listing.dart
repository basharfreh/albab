import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums/listing_purpose.dart';
import 'enums/listing_status.dart';
import 'enums/property_type.dart';
import 'listing_image.dart';
import 'user.dart';

part 'listing.freezed.dart';
part 'listing.g.dart';

/// A listing, as returned by `ListingCardSerializer` (list), `ListingDetailSerializer`
/// (retrieve — adds [description]/[images]/[lat]/[lng]/[owner]) or `AdminListingSerializer`
/// (admin/moderation — additionally adds [status]/[rejectionReason]/[createdAt]). Fields only
/// one of those shapes carries are nullable rather than three separate Dart classes.
@freezed
abstract class Listing with _$Listing {
  const factory Listing({
    required int id,
    required String title,
    String? coverThumbnail,
    String? neighborhoodName,
    @Default('') String landmark,
    String? price,
    @Default('USD') String currency,
    @Default(false) bool isNegotiable,
    String? areaSqm,
    int? bedrooms,
    int? bathrooms,
    @Default(0) int imagesCount,
    required ListingPurpose purpose,
    required PropertyType propertyType,
    @Default(false) bool isFeatured,
    @Default(false) bool isFavorited,
    // Detail-only:
    String? description,
    List<ListingImage>? images,
    String? lat,
    String? lng,
    User? owner,
    // Admin/moderation-only, and (status/rejectionReason/viewsCount/contactsCount/
    // createdAt/publishedAt) `MyListingSerializer` on `GET /me/listings/` — brief P10's
    // status-tabbed "عقاراتي" list and its per-listing stats breakdown, added when P10
    // found neither field reachable any other way (docs/API.md, PROGRESS.md P10 entry):
    ListingStatus? status,
    String? rejectionReason,
    int? viewsCount,
    int? contactsCount,
    DateTime? createdAt,
    DateTime? publishedAt,
  }) = _Listing;

  factory Listing.fromJson(Map<String, dynamic> json) => _$ListingFromJson(json);
}

/// The deliberately tiny `GET /listings/map/` marker shape — id, lat, lng, property_type,
/// purpose, price only, capped under ~120 bytes each (brief §7's P2 done-when).
@freezed
abstract class ListingMapMarker with _$ListingMapMarker {
  const factory ListingMapMarker({
    required int id,
    required String lat,
    required String lng,
    required PropertyType propertyType,
    required ListingPurpose purpose,
    String? price,
  }) = _ListingMapMarker;

  factory ListingMapMarker.fromJson(Map<String, dynamic> json) =>
      _$ListingMapMarkerFromJson(json);
}

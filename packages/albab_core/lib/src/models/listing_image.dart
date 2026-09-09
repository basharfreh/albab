import 'package:freezed_annotation/freezed_annotation.dart';

part 'listing_image.freezed.dart';
part 'listing_image.g.dart';

@freezed
abstract class ListingImage with _$ListingImage {
  const factory ListingImage({
    required int id,
    required String image,
    String? thumbnail,
    required int sortOrder,
    required bool isCover,
  }) = _ListingImage;

  factory ListingImage.fromJson(Map<String, dynamic> json) => _$ListingImageFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'neighborhood.freezed.dart';
part 'neighborhood.g.dart';

@freezed
abstract class Neighborhood with _$Neighborhood {
  const factory Neighborhood({
    required int id,
    required String nameAr,
    required String nameEn,
    required String slug,
    required String centerLat,
    required String centerLng,
  }) = _Neighborhood;

  factory Neighborhood.fromJson(Map<String, dynamic> json) => _$NeighborhoodFromJson(json);
}

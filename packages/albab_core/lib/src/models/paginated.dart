import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated.freezed.dart';
part 'paginated.g.dart';

/// DRF's `PageNumberPagination` envelope (brief §8): `{count, next, previous, results}`.
@Freezed(genericArgumentFactories: true)
abstract class Paginated<T> with _$Paginated<T> {
  const factory Paginated({
    required int count,
    String? next,
    String? previous,
    required List<T> results,
  }) = _Paginated<T>;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PaginatedFromJson(json, fromJsonT);
}

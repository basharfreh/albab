import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

/// `kind` stays a plain wire string (`listing_approved`, `listing_rejected`, `new_message`,
/// `promotion_expiring`) rather than a Dart enum — brief §7/P4 only asks for the four
/// filter/status-shaped enums (`PropertyType`, `ListingPurpose`, `ListingStatus`,
/// `UserRole`); routing on `kind` (P10) can match against `NotificationKind`-equivalent
/// string constants when that phase needs it.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required int id,
    required String kind,
    required String title,
    @Default('') String body,
    @Default({}) Map<String, dynamic> data,
    DateTime? readAt,
    required DateTime createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}

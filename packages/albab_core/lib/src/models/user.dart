import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums/user_role.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// A user, as returned by any endpoint that renders one — `UserSerializer` (public),
/// `MeSerializer` (`/auth/me/`) or `AdminUserSerializer` (`/admin/users/`). Fields only one
/// of those shapes carries (`phone`, `unreadMessages`, `isBlocked`, ...) are nullable rather
/// than split into three Dart classes, since call sites already know which endpoint they hit.
@freezed
abstract class User with _$User {
  const factory User({
    required int id,
    required String name,
    required UserRole role,
    String? avatar,
    String? agencyName,
    String? agencyLogo,
    String? phone,
    String? whatsappPhone,
    bool? isPhoneVerified,
    bool? isBlocked,
    String? blockReason,
    int? unreadMessages,
    int? unreadNotifications,
    DateTime? createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

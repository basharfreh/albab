import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/user.dart';

part 'auth_state.freezed.dart';

/// `unknown | guest | authenticated(User)` (brief P4). `unknown` is the boot-time state
/// before session restoration has resolved either way — P5's `AuthRepository` is what
/// actually checks stored tokens and calls `/auth/me/` to resolve it into `guest` or
/// `authenticated`; this provider only holds the state container and the transitions.
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unknown() = AuthStateUnknown;
  const factory AuthState.guest() = AuthStateGuest;
  const factory AuthState.authenticated(User user) = AuthStateAuthenticated;
}

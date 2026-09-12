import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _isOnline(List<ConnectivityResult> results) =>
    results.any((r) => r != ConnectivityResult.none);

/// `true` once the platform reports at least one non-`none` connectivity result. Brief P12
/// item 5's "connectivity banner" watches this — note it reflects a network *interface* being
/// up (Wi-Fi/cellular associated), not that the internet is actually reachable end to end; a
/// captive portal or a dead upstream link would still read as "online" here, same tradeoff
/// every app using this package makes rather than pinging a real endpoint on every change.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  yield _isOnline(await Connectivity().checkConnectivity());
  yield* Connectivity().onConnectivityChanged.map(_isOnline);
});

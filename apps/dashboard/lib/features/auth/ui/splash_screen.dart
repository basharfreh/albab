import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

/// Root route — mirrors `apps/mobile`'s `SplashScreen`. Kicks off
/// [AuthRepository.restoreSession] once; the router's redirect (driven by [authStateProvider]
/// leaving `unknown`) takes it from there — to `/home` for a working admin session, `/login`
/// otherwise (including a stored token for a non-admin account, which `restoreSession`
/// already dropped back to `guest`).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authRepositoryProvider).restoreSession());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(child: Icon(Icons.shield_outlined, color: AppColors.primary, size: 64)),
    );
  }
}

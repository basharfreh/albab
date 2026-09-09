import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

/// Root route. Kicks off [AuthRepository.restoreSession] once; the router's redirect (driven
/// by [authStateProvider] leaving `unknown`) takes it from there — to `/map` for a valid
/// stored session, `/welcome` otherwise. Never shown again after the first resolve.
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
      backgroundColor: AppColors.primary,
      body: Center(
        child: Icon(Icons.home_rounded, color: AppColors.surface, size: 64),
      ),
    );
  }
}

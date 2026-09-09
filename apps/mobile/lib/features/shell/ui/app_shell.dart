import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'bottom_nav_bar.dart';
import 'guest_gate.dart';

/// The five-tab shell (brief P5 item 1): wraps go_router's [StatefulNavigationShell] so each
/// tab keeps its own navigation stack and scroll position when switching away and back.
/// The home tab (index 0) is reachable by anyone; the other four are gated for a guest.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _homeIndex = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, ref, index),
      ),
    );
  }

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    final isAuthenticated = ref.read(authStateProvider) is AuthStateAuthenticated;
    if (index != _homeIndex && !isAuthenticated) {
      showGuestGateSheet(context);
      return;
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

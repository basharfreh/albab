import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Splash/welcome (brief §5 screen 1, UC-01/02/03/05): centred logo + tagline, the three
/// entry CTAs, and the language globe. Reached whenever [authStateProvider] resolves to
/// `guest` with no explicit navigation yet — tapping "متابعة كضيف" is what actually moves on
/// to `/map` (the state is already `guest`; the tap is a plain navigation, not a state
/// change) — see the router's decision note for why `guest` alone doesn't auto-redirect.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.home_rounded, color: AppColors.primary, size: 48),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.appName, style: AppTypography.display, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.authWelcomeTagline,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 4),
              PrimaryButton(label: l10n.authLogin, onPressed: () => context.push('/login')),
              const SizedBox(height: AppSpacing.md),
              SecondaryButton(
                label: l10n.authRegister,
                onPressed: () => context.push('/register'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => context.go('/map'),
                child: Text(l10n.authContinueAsGuest),
              ),
              const SizedBox(height: AppSpacing.lg),
              IconButton(
                icon: const Icon(Icons.language, color: AppColors.textSecondary),
                tooltip: locale.languageCode == 'ar' ? 'English' : 'العربية',
                onPressed: () {
                  final next = locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
                  ref.read(localeProvider.notifier).setLocale(next);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

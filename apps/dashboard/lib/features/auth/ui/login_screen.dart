import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

/// Dashboard sign-in (brief P11 item 2) — phone + password like mobile's `LoginScreen`, but
/// restricted to `role=admin`: [AuthRepository.login] throws [DashboardAccessDeniedException]
/// for any other role, shown here as [AppLocalizations.dashLoginAdminOnlyError] rather than
/// a blank screen or a generic server error.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  Map<String, List<String>> _fieldErrors = {};
  String? _formError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    final localErrors = <String, List<String>>{
      if (phone.isEmpty) 'phone': [l10n.validationRequired],
      if (password.isEmpty) 'password': [l10n.validationRequired],
    };
    if (localErrors.isNotEmpty) {
      setState(() => _fieldErrors = localErrors);
      return;
    }

    setState(() {
      _isLoading = true;
      _fieldErrors = {};
      _formError = null;
    });
    try {
      await ref.read(authRepositoryProvider).login(phone: phone, password: password);
    } on DashboardAccessDeniedException {
      setState(() => _formError = l10n.dashLoginAdminOnlyError);
    } on ApiException catch (e) {
      setState(() {
        _fieldErrors = e.fieldErrors;
        if (e.fieldErrors.isEmpty) _formError = e.localizedMessage(l10n);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.shield_outlined, size: 40, color: AppColors.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.appName, style: AppTypography.title, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.dashLoginTitle,
                      style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppTextField(
                      controller: _phoneController,
                      label: l10n.authPhone,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      errorText: _fieldErrors['phone']?.first,
                      prefixIcon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _passwordController,
                      label: l10n.authPassword,
                      obscureText: true,
                      errorText: _fieldErrors['password']?.first,
                      prefixIcon: Icons.lock_outline,
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        _formError!,
                        style: AppTypography.body.copyWith(color: AppColors.danger),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    PrimaryButton(
                      label: l10n.authLogin,
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

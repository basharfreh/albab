import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';

/// Phone + password login (UC-03). On success, [AuthRepository.login] flips
/// [authStateProvider] to `authenticated`; the router's redirect then moves off this route
/// to `/map` on its own — no explicit navigation call needed here.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialPhone});

  final String? initialPhone;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final _phoneController = TextEditingController(text: widget.initialPhone);
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
      appBar: AppBar(title: Text(l10n.authLogin)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/register'),
                  child: Text('${l10n.authNoAccountPrompt} ${l10n.authRegister}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

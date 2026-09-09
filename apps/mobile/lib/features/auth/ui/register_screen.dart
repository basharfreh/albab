import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';

/// Register (UC-02): name, phone, password, and the three role chips مالك عقار / مكتب
/// عقاري / مستخدم — `admin` is never offered here (`/auth/register/` rejects it, per
/// docs/API.md). Agency name only appears once `agency` is picked. On success this does
/// *not* log the user in (P1 decision: register returns the created user, no tokens) — it
/// moves on to `/verify` to confirm the phone (UC-04), then from there to `/login`.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _agencyNameController = TextEditingController();

  UserRole _role = UserRole.seeker;
  bool _isLoading = false;
  Map<String, List<String>> _fieldErrors = {};
  String? _formError;

  static const _selectableRoles = [UserRole.owner, UserRole.agency, UserRole.seeker];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _agencyNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final agencyName = _agencyNameController.text.trim();

    final localErrors = <String, List<String>>{
      if (name.isEmpty) 'name': [l10n.validationRequired],
      if (phone.isEmpty) 'phone': [l10n.validationRequired],
      if (password.isEmpty)
        'password': [l10n.validationRequired]
      else if (password.length < 8)
        'password': [l10n.validationPasswordTooShort],
      if (_role == UserRole.agency && agencyName.isEmpty)
        'agency_name': [l10n.validationRequired],
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
      await ref
          .read(authRepositoryProvider)
          .register(
            phone: phone,
            name: name,
            password: password,
            role: _role,
            agencyName: _role == UserRole.agency ? agencyName : null,
          );
      if (mounted) {
        context.pushReplacement('/verify', extra: {'phone': phone, 'purpose': OtpPurpose.register});
      }
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
      appBar: AppBar(title: Text(l10n.authRegister)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _nameController,
                label: l10n.authName,
                errorText: _fieldErrors['name']?.first,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(title: l10n.authChooseRole),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final role in _selectableRoles)
                    ChoiceChip(
                      label: Text(role.label(l10n)),
                      avatar: Icon(role.icon, size: AppIconSizes.inline),
                      selected: _role == role,
                      onSelected: (_) => setState(() => _role = role),
                    ),
                ],
              ),
              if (_role == UserRole.agency) ...[
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _agencyNameController,
                  label: l10n.authAgencyName,
                  errorText: _fieldErrors['agency_name']?.first,
                  prefixIcon: Icons.business_outlined,
                ),
              ],
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
                label: l10n.authRegister,
                isLoading: _isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text('${l10n.authHaveAccountPrompt} ${l10n.authLogin}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

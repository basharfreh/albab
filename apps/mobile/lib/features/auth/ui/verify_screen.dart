import 'dart:async';

import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_repository.dart';
import 'widgets/otp_code_field.dart';

/// OTP verify (UC-04): reached after registration to confirm the phone number. Backend's
/// resend throttle is 60s (docs/API.md) — the countdown here mirrors that exactly, so
/// "resend" is never tapped while the server would still 429 it.
class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key, required this.phone, required this.purpose});

  final String phone;
  final OtpPurpose purpose;

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  static const _resendSeconds = 60;

  final _otpKey = GlobalKey<OtpCodeFieldState>();
  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  String? _debugCode;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _requestCode();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _requestCode() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _errorMessage = null);
    try {
      final debugCode = await ref
          .read(authRepositoryProvider)
          .requestOtp(phone: widget.phone, purpose: widget.purpose);
      if (!mounted) return;
      setState(() => _debugCode = debugCode);
      _startCountdown();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.localizedMessage(l10n));
    }
  }

  Future<void> _verify(String code) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyOtp(phone: widget.phone, purpose: widget.purpose, code: code);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authOtpVerified)));
      context.pushReplacement('/login', extra: widget.phone);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.localizedMessage(l10n));
      _otpKey.currentState?.clear();
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayPhone = PhoneFormat.display(widget.phone);
    // Bidi isolate marks (U+2066/U+2069) keep the LTR phone number from reordering inside
    // the surrounding Arabic sentence, per brief §9's "numbers stay LTR" rule.
    final isolatedPhone = '\u2066$displayPhone\u2069';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authOtpTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.authOtpSubtitle(isolatedPhone),
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (_debugCode != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.authOtpDebugCode(_debugCode!),
                  style: AppTypography.caption.copyWith(color: AppColors.warning),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              OtpCodeField(key: _otpKey, onCompleted: _verify),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _errorMessage!,
                  style: AppTypography.body.copyWith(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              if (_isVerifying)
                const Center(child: CircularProgressIndicator())
              else
                Center(
                  child: _secondsLeft > 0
                      ? Text(
                          l10n.authOtpResendIn(_secondsLeft),
                          style: AppTypography.body.copyWith(color: AppColors.textMuted),
                        )
                      : TextButton(onPressed: _requestCode, child: Text(l10n.authOtpResend)),
                ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () => context.pushReplacement('/login', extra: widget.phone),
                  child: Text(l10n.authOtpSkip),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

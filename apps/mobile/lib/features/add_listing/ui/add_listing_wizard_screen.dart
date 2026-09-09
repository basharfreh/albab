import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/add_listing_repository.dart';
import '../data/wizard_draft.dart';
import 'quota_screen.dart';
import 'success_screen.dart';
import 'widgets/step1_info.dart';
import 'widgets/step2_location.dart';
import 'widgets/step3_photos.dart';
import 'widgets/step4_review.dart';
import 'widgets/wizard_step_header.dart';

/// UC-30…UC-34/UC-38 — the add-listing wizard (brief P9). Lives at the `/add` tab, which
/// (unlike every other tab) has no meaningful "back out of it" destination of its own — it's
/// always the wizard, never a list of something else — so "back gesture asks to save as
/// draft" (brief item 1) is implemented as: within the wizard, back steps back one page;
/// leaving step 1 sends the user to `/map` after a confirmation, since the draft is already
/// saved continuously (PATCH after every step) and there is nothing else for "back" to reveal
/// on this particular tab.
class AddListingWizardScreen extends ConsumerStatefulWidget {
  const AddListingWizardScreen({super.key});

  @override
  ConsumerState<AddListingWizardScreen> createState() =>
      _AddListingWizardScreenState();
}

class _AddListingWizardScreenState
    extends ConsumerState<AddListingWizardScreen> {
  bool _resuming = true;
  bool _busy = false;
  int? _successListingId;
  String? _quotaMessage;

  @override
  void initState() {
    super.initState();
    // Deferred a tick — same pattern as `SplashScreen`/`MapHomeScreen`: this widget is
    // mounted as part of a larger build pass (go_router's shell `Builder`), and mutating a
    // provider synchronously from `initState` trips Riverpod's "modified during build" guard.
    Future.microtask(_resume);
  }

  Future<void> _resume() async {
    final prefs = ref.read(prefsStorageProvider);
    final draftId = await prefs.readWizardDraftId();
    final notifier = ref.read(wizardDraftProvider.notifier);
    if (draftId == null) {
      notifier.reset();
      if (mounted) setState(() => _resuming = false);
      return;
    }
    try {
      final listing = await ref
          .read(addListingRepositoryProvider)
          .fetchListing(draftId);
      final step = await prefs.readWizardStep();
      notifier.load(WizardDraft.fromListing(listing).copyWith(step: step));
    } on ApiException {
      // The remembered draft is gone or no longer reachable (deleted, submitted through
      // another session) — nothing to resume, start clean rather than get stuck loading.
      await prefs.clearWizardProgress();
      notifier.reset();
    }
    if (mounted) setState(() => _resuming = false);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleNext() async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(wizardDraftProvider.notifier);
    final draft = ref.read(wizardDraftProvider);
    final repo = ref.read(addListingRepositoryProvider);
    final prefs = ref.read(prefsStorageProvider);

    switch (draft.step) {
      case 0:
        if (!draft.step1Valid) {
          _showSnack(
            draft.title.trim().isEmpty
                ? l10n.validationRequired
                : l10n.validationPriceInvalid,
          );
          return;
        }
        setState(() => _busy = true);
        try {
          int listingId;
          if (draft.listingId == null) {
            final listing = await repo.createDraft(draft);
            notifier.setListingId(listing.id);
            listingId = listing.id;
          } else {
            listingId = draft.listingId!;
            await repo.patchStep1(listingId, draft);
          }
          await prefs.saveWizardProgress(draftId: listingId, step: 1);
          notifier.setStep(1);
        } on ApiException catch (e) {
          _showSnack(e.localizedMessage(l10n));
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      case 1:
        if (!draft.hasLocation) {
          _showSnack(l10n.wizardLocationRequired);
          return;
        }
        setState(() => _busy = true);
        try {
          await repo.patchLocation(draft.listingId!, draft);
          await prefs.saveWizardProgress(draftId: draft.listingId!, step: 2);
          notifier.setStep(2);
        } on ApiException catch (e) {
          _showSnack(e.localizedMessage(l10n));
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      case 2:
        if (draft.images.isEmpty) {
          _showSnack(l10n.wizardPhotosRequired);
          return;
        }
        if (draft.images.any((image) => image.uploading)) {
          _showSnack(l10n.commonLoading);
          return;
        }
        await prefs.saveWizardProgress(draftId: draft.listingId!, step: 3);
        notifier.setStep(3);
      case 3:
        await _submit();
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final draft = ref.read(wizardDraftProvider);
    setState(() => _busy = true);
    try {
      await ref.read(addListingRepositoryProvider).submit(draft.listingId!);
      await ref.read(prefsStorageProvider).clearWizardProgress();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _successListingId = draft.listingId;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (e.fieldErrors.isNotEmpty) {
        // brief P9 item 7 only asks for a friendly screen on the *quota* rejection — a
        // missing-field error (images/price/location/neighborhood) means the wizard's own
        // client-side validation missed something server-side validation still caught, so
        // send the user back to whichever step owns that field instead.
        ref
            .read(wizardDraftProvider.notifier)
            .setStep(_stepForFieldErrors(e.fieldErrors.keys));
        _showSnack(e.fieldErrors.values.first.first);
      } else {
        setState(() => _quotaMessage = e.localizedMessage(l10n));
      }
    }
  }

  int _stepForFieldErrors(Iterable<String> fields) {
    if (fields.contains('images')) return 2;
    if (fields.contains('location') || fields.contains('neighborhood')) {
      return 1;
    }
    return 0;
  }

  Future<void> _handleBack() async {
    final draft = ref.read(wizardDraftProvider);
    if (draft.step == 0) {
      await _confirmExit();
      return;
    }
    final newStep = draft.step - 1;
    ref.read(wizardDraftProvider.notifier).setStep(newStep);
    if (draft.listingId != null) {
      await ref
          .read(prefsStorageProvider)
          .saveWizardProgress(draftId: draft.listingId!, step: newStep);
    }
  }

  Future<void> _confirmExit() async {
    final draft = ref.read(wizardDraftProvider);
    if (draft.listingId == null) {
      // Nothing created server-side yet — there is no draft to save, so there's nothing to
      // confirm either.
      if (mounted) context.go('/map');
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.wizardExitConfirmTitle),
        content: Text(l10n.wizardExitConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.wizardExitConfirmContinue),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.wizardExitConfirmExit),
          ),
        ],
      ),
    );
    if (exit == true && mounted) context.go('/map');
  }

  void _startAnother() {
    ref.read(wizardDraftProvider.notifier).reset();
    setState(() {
      _successListingId = null;
      _quotaMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_resuming) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final successId = _successListingId;
    if (successId != null) {
      return AddListingSuccessScreen(
        listingId: successId,
        onAddAnother: _startAnother,
      );
    }

    final quotaMessage = _quotaMessage;
    if (quotaMessage != null) {
      return QuotaScreen(message: quotaMessage, onClose: _startAnother);
    }

    final draft = ref.watch(wizardDraftProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _busy ? null : _handleBack,
                    ),
                    Expanded(child: WizardStepHeader(currentStep: draft.step)),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: switch (draft.step) {
                  0 => const Step1Info(),
                  1 => const Step2Location(),
                  2 => const Step3Photos(),
                  _ => Step4Review(
                    onEditStep: (step) {
                      ref.read(wizardDraftProvider.notifier).setStep(step);
                    },
                  ),
                },
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: PrimaryButton(
                    label: draft.step == 3
                        ? l10n.wizardPublishListing
                        : l10n.commonNext,
                    isLoading: _busy,
                    onPressed: _busy ? null : _handleNext,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

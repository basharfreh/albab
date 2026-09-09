import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';

/// The 4-step header (brief P9 item 1): completed steps green with a check, the current
/// step outlined, future steps grey. Purely presentational — [currentStep] is 0-indexed.
class WizardStepHeader extends StatelessWidget {
  const WizardStepHeader({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.wizardStepInfo,
      l10n.wizardStepLocation,
      l10n.wizardStepPhotos,
      l10n.wizardStepReview,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) Expanded(child: _Connector(done: i <= currentStep)),
            _StepDot(index: i, label: labels[i], state: _stateFor(i)),
          ],
        ],
      ),
    );
  }

  _DotState _stateFor(int index) {
    if (index < currentStep) return _DotState.done;
    if (index == currentStep) return _DotState.current;
    return _DotState.upcoming;
  }
}

enum _DotState { done, current, upcoming }

class _Connector extends StatelessWidget {
  const _Connector({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      color: done ? AppColors.primary : AppColors.border,
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.state,
  });

  final int index;
  final String label;
  final _DotState state;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final Color border;
    switch (state) {
      case _DotState.done:
        background = AppColors.primary;
        foreground = AppColors.surface;
        border = AppColors.primary;
      case _DotState.current:
        background = AppColors.surface;
        foreground = AppColors.primary;
        border = AppColors.primary;
      case _DotState.upcoming:
        background = AppColors.surface;
        foreground = AppColors.textMuted;
        border = AppColors.border;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 2),
          ),
          child: state == _DotState.done
              ? const Icon(Icons.check, size: 16, color: AppColors.surface)
              : Text(
                  '${index + 1}',
                  style: AppTypography.label.copyWith(color: foreground),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: state == _DotState.upcoming
                ? AppColors.textMuted
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

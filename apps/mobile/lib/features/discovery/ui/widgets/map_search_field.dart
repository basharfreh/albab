import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _expandedTopRadius = 20.0;

/// The map screen's search bar (UC-12) plus its recent-searches panel (brief P7 item 5):
/// shown while the field is focused and empty, capped at
/// [PrefsStorage.maxRecentSearches], clearable. Submitting — by keyboard action or tapping
/// a suggestion — always persists the term locally; interpreting it as a place vs. a
/// free-text filter is the map screen's own job (see [onSubmitted]'s caller), not this
/// widget's.
class MapSearchField extends ConsumerStatefulWidget {
  const MapSearchField({super.key, required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  ConsumerState<MapSearchField> createState() => _MapSearchFieldState();
}

class _MapSearchFieldState extends ConsumerState<MapSearchField> {
  final _focusNode = FocusNode();
  List<String> _recent = const [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
    _loadRecent();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final recent = await ref.read(prefsStorageProvider).readRecentSearches();
    if (mounted) setState(() => _recent = recent);
  }

  Future<void> _submit(String value) async {
    final trimmed = value.trim();
    _focusNode.unfocus();
    widget.onSubmitted(trimmed);
    if (trimmed.isNotEmpty) {
      // Awaited in order (not fire-and-forget) — reloading before the write lands would
      // race and could show the list without the term that was just submitted.
      await ref.read(prefsStorageProvider).addRecentSearch(trimmed);
      await _loadRecent();
    }
  }

  void _selectRecent(String value) {
    widget.controller.text = value;
    _submit(value);
  }

  Future<void> _clearRecent() async {
    await ref.read(prefsStorageProvider).clearRecentSearches();
    if (mounted) setState(() => _recent = const []);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showSuggestions =
        _focusNode.hasFocus && widget.controller.text.isEmpty && _recent.isNotEmpty;

    return Material(
      elevation: 2,
      shadowColor: Colors.black26,
      color: AppColors.surface,
      borderRadius: showSuggestions
          ? const BorderRadius.vertical(top: Radius.circular(_expandedTopRadius))
          : AppRadius.pillRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: _submit,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.searchPlaceholder,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: showSuggestions
                    ? const BorderRadius.vertical(top: Radius.circular(_expandedTopRadius))
                    : AppRadius.pillRadius,
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          if (showSuggestions) ..._buildSuggestions(l10n),
        ],
      ),
    );
  }

  List<Widget> _buildSuggestions(AppLocalizations l10n) {
    return [
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.searchRecentTitle,
              style: AppTypography.label.copyWith(color: AppColors.textSecondary),
            ),
            TextButton(onPressed: _clearRecent, child: Text(l10n.searchRecentClear)),
          ],
        ),
      ),
      for (final term in _recent)
        ListTile(
          dense: true,
          leading: const Icon(Icons.history, size: AppIconSizes.inline),
          title: Text(term),
          onTap: () => _selectRecent(term),
        ),
      const SizedBox(height: AppSpacing.sm),
    ];
  }
}

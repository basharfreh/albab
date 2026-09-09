import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../map/data/listings_repository.dart';

/// The sticky bottom action bar (brief P8 item 3): two filled green buttons side by
/// side — the one brief §9 exception to "never two filled greens side by side". Each posts
/// its `call`/`whatsapp` event before launching (brief: "Every contact action is logged").
class ContactBar extends StatelessWidget {
  const ContactBar({super.key, required this.listing, required this.onEvent});

  final Listing listing;
  final void Function(ListingEventKind kind) onEvent;

  Future<void> _launch(BuildContext context, Uri uri, ListingEventKind kind) async {
    onEvent(kind);
    final l10n = AppLocalizations.of(context)!;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication).catchError(
      (_) => false,
    );
    // wa.me/tel: URIs failing `externalApplication` (no app registered to handle them) —
    // fall back to the platform default, which for `wa.me` opens it as a normal web URL
    // (brief: "If no WhatsApp app is installed, fall back to the web URL").
    if (!launched) {
      final fallback = await launchUrl(uri).catchError((_) => false);
      if (!fallback && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.contactLaunchFailed)));
      }
    }
  }

  void _call(BuildContext context) {
    final phone = listing.owner?.phone;
    if (phone == null) return;
    _launch(context, Uri(scheme: 'tel', path: phone), ListingEventKind.call);
  }

  void _whatsapp(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final phone = listing.owner?.whatsappPhone ?? listing.owner?.phone;
    if (phone == null) return;
    final digits = phone.startsWith('+') ? phone.substring(1) : phone;
    final price = listing.price == null ? '' : Money.format(listing.price!);
    final message = l10n.contactWhatsappMessage(listing.title, price);
    final uri = Uri.https('wa.me', '/$digits', {'text': message});
    _launch(context, uri, ListingEventKind.whatsapp);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surface, boxShadow: AppShadows.sheet),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: l10n.listingWhatsapp,
                  icon: Icons.chat_outlined,
                  onPressed: () => _whatsapp(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label: l10n.listingCall,
                  icon: Icons.call_outlined,
                  onPressed: () => _call(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Mirrors `apps.accounts.models.UserRole` on the backend — wire values are the enum
/// names themselves (`seeker`, `owner`, `agency`, `admin`), so JSON (de)serialization
/// is the default `.name`-based one json_serializable generates for enums.
enum UserRole {
  seeker(icon: Icons.person_outline),
  owner(icon: Icons.home_outlined),
  agency(icon: Icons.business_outlined),
  admin(icon: Icons.shield_outlined);

  const UserRole({required this.icon});

  final IconData icon;

  String get wireValue => name;

  String label(AppLocalizations l10n) => switch (this) {
    UserRole.seeker => l10n.roleSeeker,
    UserRole.owner => l10n.roleOwner,
    UserRole.agency => l10n.roleAgency,
    UserRole.admin => l10n.roleAdmin,
  };
}

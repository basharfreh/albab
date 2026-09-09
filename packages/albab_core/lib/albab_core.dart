/// Shared Dart/Flutter code for both `apps/mobile` and `apps/dashboard`: theme, l10n,
/// formatters, API client, models, secure/local storage, common widgets, and the app-wide
/// Riverpod providers. No screens, no feature repositories — see brief §7/P4.
library;

export 'l10n/app_localizations.dart';

export 'src/api/api_client.dart';
export 'src/api/api_exception.dart';

export 'src/format/area.dart';
export 'src/format/money.dart';
export 'src/format/phone_format.dart';
export 'src/format/relative_time.dart';

export 'src/models/conversation.dart';
export 'src/models/enums/listing_purpose.dart';
export 'src/models/enums/listing_status.dart';
export 'src/models/enums/property_type.dart';
export 'src/models/enums/user_role.dart';
export 'src/models/listing.dart';
export 'src/models/listing_image.dart';
export 'src/models/message.dart';
export 'src/models/neighborhood.dart';
export 'src/models/notification.dart';
export 'src/models/paginated.dart';
export 'src/models/user.dart';

export 'src/providers/auth_state.dart';
export 'src/providers/providers.dart';

export 'src/storage/prefs_storage.dart';
export 'src/storage/token_storage.dart';

export 'src/theme/app_colors.dart';
export 'src/theme/app_icon_sizes.dart';
export 'src/theme/app_radius.dart';
export 'src/theme/app_shadows.dart';
export 'src/theme/app_spacing.dart';
export 'src/theme/app_theme.dart';
export 'src/theme/app_typography.dart';

export 'src/widgets/app_badge.dart';
export 'src/widgets/app_dropdown.dart';
export 'src/widgets/app_text_field.dart';
export 'src/widgets/counter_field.dart';
export 'src/widgets/empty_state.dart';
export 'src/widgets/error_state.dart';
export 'src/widgets/listing_card.dart';
export 'src/widgets/loading_skeleton.dart';
export 'src/widgets/price_range_slider.dart';
export 'src/widgets/primary_button.dart';
export 'src/widgets/property_stats_row.dart';
export 'src/widgets/secondary_button.dart';
export 'src/widgets/section_header.dart';

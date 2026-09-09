// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Al-Bab Real Estate';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonDone => 'Done';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonViewAll => 'View all';

  @override
  String get commonUndo => 'Undo';

  @override
  String get authLogin => 'Log in';

  @override
  String get authRegister => 'Create account';

  @override
  String get authContinueAsGuest => 'Continue as guest';

  @override
  String get authLogout => 'Log out';

  @override
  String get authPhone => 'Phone number';

  @override
  String get authPassword => 'Password';

  @override
  String get authName => 'Name';

  @override
  String get authAgencyName => 'Agency name';

  @override
  String get authWelcomeTagline => 'Find your next home in Al-Bab';

  @override
  String get authNoAccountPrompt => 'Don\'t have an account?';

  @override
  String get authHaveAccountPrompt => 'Already have an account?';

  @override
  String get authChooseRole => 'Account type';

  @override
  String get authOtpTitle => 'Verify your phone number';

  @override
  String authOtpSubtitle(String phone) {
    return 'Enter the code sent to $phone';
  }

  @override
  String authOtpDebugCode(String code) {
    return '(dev) Code: $code';
  }

  @override
  String authOtpResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get authOtpResend => 'Resend code';

  @override
  String get authOtpVerify => 'Verify';

  @override
  String get authOtpVerified => 'Phone number verified';

  @override
  String get authOtpSkip => 'Skip for now';

  @override
  String get authGuestGateTitle => 'Sign in to continue';

  @override
  String get authGuestGateMessage => 'You need an account to use this feature';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationPhoneInvalid => 'Invalid phone number';

  @override
  String get validationPasswordTooShort =>
      'Password must be at least 8 characters';

  @override
  String get validationOtpIncomplete => 'Enter the full code';

  @override
  String get validationPriceInvalid => 'Enter a valid price';

  @override
  String get roleSeeker => 'Seeker';

  @override
  String get roleOwner => 'Property owner';

  @override
  String get roleAgency => 'Real estate agency';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get propertyTypeHouse => 'House';

  @override
  String get propertyTypeApartment => 'Apartment';

  @override
  String get propertyTypeShop => 'Shop';

  @override
  String get propertyTypeLand => 'Land';

  @override
  String get propertyTypeOther => 'Other';

  @override
  String get purposeSale => 'For sale';

  @override
  String get purposeRent => 'For rent';

  @override
  String get listingStatusDraft => 'Draft';

  @override
  String get listingStatusPending => 'Pending review';

  @override
  String get listingStatusPublished => 'Published';

  @override
  String get listingStatusRejected => 'Rejected';

  @override
  String get listingStatusSold => 'Sold';

  @override
  String get listingStatusRented => 'Rented';

  @override
  String get listingStatusPaused => 'Paused';

  @override
  String get navHome => 'Home';

  @override
  String get navMessages => 'Messages';

  @override
  String get navAdd => 'Add listing';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navAccount => 'Account';

  @override
  String get dashNavHome => 'Home';

  @override
  String get dashNavListings => 'Listings';

  @override
  String get dashNavUsers => 'Users';

  @override
  String get dashNavPromotions => 'Promotions';

  @override
  String get dashNavTransactions => 'Transactions';

  @override
  String get dashNavNotifications => 'Notifications';

  @override
  String get dashNavReports => 'Reports';

  @override
  String get dashNavSettings => 'Settings';

  @override
  String get wizardStepInfo => 'Info';

  @override
  String get wizardStepLocation => 'Location';

  @override
  String get wizardStepPhotos => 'Photos';

  @override
  String get wizardStepReview => 'Review';

  @override
  String get wizardTitleLabel => 'Listing title';

  @override
  String get wizardTitleHint => 'e.g. House in Al-Hussein district';

  @override
  String get wizardPriceLabel => 'Price';

  @override
  String get wizardNegotiable => 'Negotiable';

  @override
  String get wizardDescriptionLabel => 'Description';

  @override
  String get wizardBedroomsCount => 'Bedrooms';

  @override
  String get wizardBathroomsCount => 'Bathrooms';

  @override
  String get wizardDragMapHint => 'Drag the map to pinpoint the location';

  @override
  String get wizardConfirmLocation => 'Confirm location';

  @override
  String get wizardLandmarkLabel => 'Nearest landmark (optional)';

  @override
  String get wizardLandmarkHint => 'e.g. near Al-Nour mosque';

  @override
  String get wizardLocationRequired => 'Pick a location on the map first';

  @override
  String get wizardSetCoverPhoto => 'Set as cover photo';

  @override
  String get wizardPickFromGallery => 'Choose from gallery';

  @override
  String get wizardTakePhoto => 'Take a photo';

  @override
  String wizardPhotosCount(int count) {
    return '$count/15 photos';
  }

  @override
  String get wizardPhotosMaxReached => 'You\'ve reached the limit (15 photos).';

  @override
  String get wizardPhotoDeleted => 'Photo deleted.';

  @override
  String get wizardPhotosRequired => 'Add at least one photo.';

  @override
  String get wizardPublishListing => 'Publish listing';

  @override
  String get wizardModerationNotice =>
      'Your listing will be reviewed within 24 hours';

  @override
  String get wizardSuccessTitle => 'Your listing was sent for review';

  @override
  String get wizardSuccessViewListing => 'View listing';

  @override
  String get wizardSuccessAddAnother => 'Add another listing';

  @override
  String get wizardPromotionEntry => 'Feature this listing';

  @override
  String get wizardPromotionComingSoonTitle => 'Featured listings';

  @override
  String get wizardPromotionComingSoonMessage =>
      'Requesting a featured placement is coming soon. Contact support to ask about promotion packages.';

  @override
  String get wizardQuotaTitle => 'You\'ve reached your limit';

  @override
  String get wizardQuotaUpgradeCta => 'Upgrade to an agency account';

  @override
  String get wizardQuotaUpgradeInfo =>
      'To upgrade to an agency account for a larger quota, contact support.';

  @override
  String get wizardExitConfirmTitle => 'Leave the wizard';

  @override
  String get wizardExitConfirmMessage =>
      'Your listing was saved as a draft — you can finish it later from My listings.';

  @override
  String get wizardExitConfirmContinue => 'Keep editing';

  @override
  String get wizardExitConfirmExit => 'Exit';

  @override
  String get locationPickerTitle => 'Choose the property\'s location';

  @override
  String get searchPlaceholder => 'Search a property or place';

  @override
  String get searchRecentTitle => 'Recent searches';

  @override
  String get searchRecentClear => 'Clear all';

  @override
  String get filterTitle => 'Search & filter';

  @override
  String get filterAll => 'All';

  @override
  String get filterPropertyType => 'Property type';

  @override
  String get filterNeighborhood => 'Neighborhood';

  @override
  String get filterPrice => 'Price';

  @override
  String get filterPriceFrom => 'From';

  @override
  String get filterPriceTo => 'To';

  @override
  String get filterArea => 'Area';

  @override
  String get filterBedroomsLabel => 'Bedrooms';

  @override
  String get filterBedroomsAll => 'All';

  @override
  String get filterBedrooms5Plus => '5+';

  @override
  String filterShowResults(int count) {
    return 'Show results ($count)';
  }

  @override
  String get filterReset => 'Reset';

  @override
  String get mapEmptyTitle => 'No properties in this area';

  @override
  String get mapEmptyMessage => 'Try widening your search';

  @override
  String get mapViewToggleMap => 'Map';

  @override
  String get mapViewToggleList => 'List';

  @override
  String get mapSearchThisArea => 'Search this area';

  @override
  String get mapMarkersTruncated =>
      'Only the closest 500 results are shown. Zoom in to see more.';

  @override
  String get listingPropertyInfo => 'Property information';

  @override
  String get listingNegotiable => 'Negotiable';

  @override
  String get listingWhatsapp => 'WhatsApp';

  @override
  String get listingCall => 'Call';

  @override
  String get listingReport => 'Report this listing';

  @override
  String get listingSimilar => 'Similar properties';

  @override
  String listingMemberSince(String date) {
    return 'Member since $date';
  }

  @override
  String get listingGalleryEmpty => 'No photos for this listing';

  @override
  String get commonShare => 'Share';

  @override
  String get commonMore => 'More';

  @override
  String get reportSheetTitle => 'Report this listing';

  @override
  String get reportReasonLabel => 'Reason';

  @override
  String get reportReasonInappropriate => 'Inappropriate content';

  @override
  String get reportReasonMisleading => 'Misleading information';

  @override
  String get reportReasonDuplicate => 'Duplicate listing';

  @override
  String get reportReasonFraud => 'Scam or fraud';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportNoteLabel => 'Note (optional)';

  @override
  String get reportSubmit => 'Submit report';

  @override
  String get reportSubmitted => 'Report submitted.';

  @override
  String shareCaption(String title, String url) {
    return '$title on Al-Bab Real Estate: $url';
  }

  @override
  String contactWhatsappMessage(String title, String price) {
    return 'Hello, I\'m interested in this listing: $title - $price';
  }

  @override
  String get contactLaunchFailed => 'Couldn\'t open the required app.';

  @override
  String get accountMyListings => 'My listings';

  @override
  String get accountFavorites => 'Favorites';

  @override
  String get accountMessages => 'Messages';

  @override
  String get accountNotifications => 'Notifications';

  @override
  String get accountStats => 'My listing views stats';

  @override
  String get accountSettings => 'Settings';

  @override
  String get accountMarkAllRead => 'Mark all as read';

  @override
  String get myListingsStatusAll => 'All';

  @override
  String get myListingsStatusPublished => 'Published';

  @override
  String get myListingsStatusPending => 'Pending';

  @override
  String get myListingsStatusRejected => 'Rejected';

  @override
  String get myListingsStatusSoldRented => 'Sold/Rented';

  @override
  String get myListingsActionEdit => 'Edit';

  @override
  String get myListingsActionPromote => 'Promote';

  @override
  String get myListingsActionPause => 'Pause';

  @override
  String get myListingsActionDelete => 'Delete';

  @override
  String get dashKpiTotalUsers => 'Total users';

  @override
  String get dashKpiTotalListings => 'Total listings';

  @override
  String get dashKpiForSale => 'For sale';

  @override
  String get dashKpiForRent => 'For rent';

  @override
  String get dashVisitsLast30Days => 'Visits, last 30 days';

  @override
  String get dashListingsByType => 'Listings by type';

  @override
  String get dashLatestListings => 'Latest listings';

  @override
  String get dashMostViewed => 'Most viewed';

  @override
  String get emptyStateDefaultTitle => 'Nothing here yet';

  @override
  String get errorStateDefaultTitle => 'Something went wrong';

  @override
  String get errorNetwork =>
      'Couldn\'t reach the server. Check your internet connection.';

  @override
  String get errorTimeout => 'The connection to the server timed out.';

  @override
  String get errorUnauthorized => 'You need to be logged in to do that.';

  @override
  String get errorUnknown => 'Something unexpected went wrong.';

  @override
  String get statsAreaLabel => 'Area';

  @override
  String get statsBedroomsLabel => 'Bedrooms';

  @override
  String get statsBathroomsLabel => 'Bathrooms';

  @override
  String areaUnit(String value) {
    return '$value m²';
  }

  @override
  String get relativeTimeJustNow => 'Just now';

  @override
  String relativeTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return '$count $_temp0 ago';
  }

  @override
  String relativeTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hours',
      one: 'hour',
    );
    return '$count $_temp0 ago';
  }

  @override
  String relativeTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$count $_temp0 ago';
  }

  @override
  String relativeTimeWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'weeks',
      one: 'week',
    );
    return '$count $_temp0 ago';
  }

  @override
  String relativeTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'months',
      one: 'month',
    );
    return '$count $_temp0 ago';
  }

  @override
  String relativeTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'years',
      one: 'year',
    );
    return '$count $_temp0 ago';
  }

  @override
  String get accountGuestPromptTitle => 'Sign in to access your account';

  @override
  String get accountGuestPromptMessage =>
      'Favorites, messages, notifications and publishing a listing need an account.';

  @override
  String get myListingsEmptyTitle => 'No listings yet';

  @override
  String get myListingsEmptyMessage =>
      'Your published and pending listings show up here.';

  @override
  String get myListingsDeleteConfirmTitle => 'Delete this listing?';

  @override
  String get myListingsDeleteConfirmMessage => 'This action can\'t be undone.';

  @override
  String get myListingsActionRepublish => 'Republish';

  @override
  String get myListingsRejectionReasonLabel => 'Rejection reason';

  @override
  String myListingsViewsCount(int count) {
    return '$count views';
  }

  @override
  String get myListingsDeleted => 'Listing deleted';

  @override
  String get myListingsStatusUpdated => 'Listing status updated';

  @override
  String get statsLast30Days => 'Last 30 days';

  @override
  String get statsTotalViews => 'Total views';

  @override
  String get statsTotalContacts => 'Total contacts';

  @override
  String get statsByChannelTitle => 'Contacts by channel';

  @override
  String get statsChannelMessage => 'Message';

  @override
  String get statsPerListingTitle => 'Per-listing performance';

  @override
  String get statsEmptyMessage => 'No view data yet.';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptyMessage =>
      'Tap the heart icon on any listing to add it here.';

  @override
  String get favoritesRemoved => 'Removed from favorites';

  @override
  String get messagesEmptyTitle => 'No messages yet';

  @override
  String get messagesEmptyMessage =>
      'Contact a listing\'s owner to start a conversation.';

  @override
  String get messageInputHint => 'Write a message...';

  @override
  String get messageSendFailed => 'Message failed to send';

  @override
  String get messagesConversationEmpty =>
      'Start the conversation with a message.';

  @override
  String get notificationsEmptyTitle => 'No notifications';

  @override
  String get notificationsEmptyMessage =>
      'Updates about your listings and messages show up here.';

  @override
  String get notificationsSectionToday => 'Today';

  @override
  String get notificationsSectionYesterday => 'Yesterday';

  @override
  String get notificationsSectionEarlier => 'Earlier';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsPushToggleLabel => 'Push notifications';

  @override
  String get settingsEditProfile => 'Edit profile';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutBody =>
      'Al-Bab Real Estate — a property marketplace for the city of Al-Bab, Syria.';

  @override
  String get settingsContactSupport => 'Contact support';

  @override
  String get settingsContactSupportMessage =>
      'For any inquiry, contact us on WhatsApp.';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountConfirmTitle => 'Delete account?';

  @override
  String get settingsDeleteAccountConfirmMessage =>
      'Your account and all its data will be permanently deleted.';

  @override
  String get settingsNotAvailableMessage =>
      'This feature isn\'t available yet — contact support.';

  @override
  String get settingsVersionLabel => 'Version';

  @override
  String get editProfileWhatsappLabel => 'WhatsApp number (optional)';

  @override
  String get editProfileSaved => 'Changes saved';

  @override
  String get editProfileChangePhoto => 'Change photo';

  @override
  String get commonSend => 'Send';
}

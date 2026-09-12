import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// App name, shown on the splash/welcome screen
  ///
  /// In ar, this message translates to:
  /// **'الباب العقاري'**
  String get appName;

  /// No description provided for @commonRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get commonSave;

  /// No description provided for @commonAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get commonAdd;

  /// No description provided for @commonCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get commonConfirm;

  /// No description provided for @commonEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get commonDelete;

  /// No description provided for @commonBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get commonNext;

  /// No description provided for @commonDone.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get commonDone;

  /// No description provided for @commonLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل...'**
  String get commonLoading;

  /// No description provided for @commonViewAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get commonViewAll;

  /// No description provided for @commonUndo.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get commonUndo;

  /// No description provided for @authLogin.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authRegister;

  /// No description provided for @authContinueAsGuest.
  ///
  /// In ar, this message translates to:
  /// **'متابعة كضيف'**
  String get authContinueAsGuest;

  /// No description provided for @authLogout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get authLogout;

  /// No description provided for @authPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get authPhone;

  /// No description provided for @authPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get authPassword;

  /// No description provided for @authName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get authName;

  /// No description provided for @authAgencyName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المكتب'**
  String get authAgencyName;

  /// No description provided for @authWelcomeTagline.
  ///
  /// In ar, this message translates to:
  /// **'اعثر على منزلك القادم في الباب'**
  String get authWelcomeTagline;

  /// No description provided for @authNoAccountPrompt.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get authNoAccountPrompt;

  /// No description provided for @authHaveAccountPrompt.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get authHaveAccountPrompt;

  /// No description provided for @authChooseRole.
  ///
  /// In ar, this message translates to:
  /// **'نوع الحساب'**
  String get authChooseRole;

  /// No description provided for @authOtpTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من رقم الهاتف'**
  String get authOtpTitle;

  /// No description provided for @authOtpSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز المرسل إلى {phone}'**
  String authOtpSubtitle(String phone);

  /// No description provided for @authOtpDebugCode.
  ///
  /// In ar, this message translates to:
  /// **'(للتجربة) الرمز: {code}'**
  String authOtpDebugCode(String code);

  /// No description provided for @authOtpResendIn.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإرسال خلال {seconds} ثانية'**
  String authOtpResendIn(int seconds);

  /// No description provided for @authOtpResend.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الرمز'**
  String get authOtpResend;

  /// No description provided for @authOtpVerify.
  ///
  /// In ar, this message translates to:
  /// **'تحقق'**
  String get authOtpVerify;

  /// No description provided for @authOtpVerified.
  ///
  /// In ar, this message translates to:
  /// **'تم التحقق من رقم الهاتف'**
  String get authOtpVerified;

  /// No description provided for @authOtpSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي الآن'**
  String get authOtpSkip;

  /// No description provided for @authGuestGateTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول للمتابعة'**
  String get authGuestGateTitle;

  /// No description provided for @authGuestGateMessage.
  ///
  /// In ar, this message translates to:
  /// **'يلزم إنشاء حساب أو تسجيل الدخول لاستخدام هذه الميزة'**
  String get authGuestGateMessage;

  /// No description provided for @validationRequired.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get validationRequired;

  /// No description provided for @validationPhoneInvalid.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف غير صحيح'**
  String get validationPhoneInvalid;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور يجب ألا تقل عن 8 أحرف'**
  String get validationPasswordTooShort;

  /// No description provided for @validationOtpIncomplete.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز كاملاً'**
  String get validationOtpIncomplete;

  /// No description provided for @validationPriceInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل سعراً صحيحاً'**
  String get validationPriceInvalid;

  /// No description provided for @roleSeeker.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم'**
  String get roleSeeker;

  /// No description provided for @roleOwner.
  ///
  /// In ar, this message translates to:
  /// **'مالك عقار'**
  String get roleOwner;

  /// No description provided for @roleAgency.
  ///
  /// In ar, this message translates to:
  /// **'مكتب عقاري'**
  String get roleAgency;

  /// No description provided for @roleAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مشرف'**
  String get roleAdmin;

  /// No description provided for @propertyTypeHouse.
  ///
  /// In ar, this message translates to:
  /// **'منزل'**
  String get propertyTypeHouse;

  /// No description provided for @propertyTypeApartment.
  ///
  /// In ar, this message translates to:
  /// **'شقة'**
  String get propertyTypeApartment;

  /// No description provided for @propertyTypeShop.
  ///
  /// In ar, this message translates to:
  /// **'محل'**
  String get propertyTypeShop;

  /// No description provided for @propertyTypeLand.
  ///
  /// In ar, this message translates to:
  /// **'أرض'**
  String get propertyTypeLand;

  /// No description provided for @propertyTypeOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get propertyTypeOther;

  /// No description provided for @purposeSale.
  ///
  /// In ar, this message translates to:
  /// **'للبيع'**
  String get purposeSale;

  /// No description provided for @purposeRent.
  ///
  /// In ar, this message translates to:
  /// **'للإيجار'**
  String get purposeRent;

  /// No description provided for @listingStatusDraft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get listingStatusDraft;

  /// No description provided for @listingStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get listingStatusPending;

  /// No description provided for @listingStatusPublished.
  ///
  /// In ar, this message translates to:
  /// **'منشور'**
  String get listingStatusPublished;

  /// No description provided for @listingStatusRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get listingStatusRejected;

  /// No description provided for @listingStatusSold.
  ///
  /// In ar, this message translates to:
  /// **'مباع'**
  String get listingStatusSold;

  /// No description provided for @listingStatusRented.
  ///
  /// In ar, this message translates to:
  /// **'مؤجر'**
  String get listingStatusRented;

  /// No description provided for @listingStatusPaused.
  ///
  /// In ar, this message translates to:
  /// **'معلق'**
  String get listingStatusPaused;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navMessages.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل'**
  String get navMessages;

  /// No description provided for @navAdd.
  ///
  /// In ar, this message translates to:
  /// **'أضف عقار'**
  String get navAdd;

  /// No description provided for @navFavorites.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة'**
  String get navFavorites;

  /// No description provided for @navAccount.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get navAccount;

  /// No description provided for @dashNavHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get dashNavHome;

  /// No description provided for @dashNavListings.
  ///
  /// In ar, this message translates to:
  /// **'العقارات'**
  String get dashNavListings;

  /// No description provided for @dashNavUsers.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمين'**
  String get dashNavUsers;

  /// No description provided for @dashNavPromotions.
  ///
  /// In ar, this message translates to:
  /// **'الإعلانات'**
  String get dashNavPromotions;

  /// No description provided for @dashNavTransactions.
  ///
  /// In ar, this message translates to:
  /// **'المعاملات'**
  String get dashNavTransactions;

  /// No description provided for @dashNavNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get dashNavNotifications;

  /// No description provided for @dashNavReports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get dashNavReports;

  /// No description provided for @dashNavSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get dashNavSettings;

  /// No description provided for @wizardStepInfo.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات'**
  String get wizardStepInfo;

  /// No description provided for @wizardStepLocation.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get wizardStepLocation;

  /// No description provided for @wizardStepPhotos.
  ///
  /// In ar, this message translates to:
  /// **'الصور'**
  String get wizardStepPhotos;

  /// No description provided for @wizardStepReview.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة'**
  String get wizardStepReview;

  /// No description provided for @wizardTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الإعلان'**
  String get wizardTitleLabel;

  /// No description provided for @wizardTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: منزل في حي الحسين'**
  String get wizardTitleHint;

  /// No description provided for @wizardPriceLabel.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get wizardPriceLabel;

  /// No description provided for @wizardNegotiable.
  ///
  /// In ar, this message translates to:
  /// **'قابل للتفاوض'**
  String get wizardNegotiable;

  /// No description provided for @wizardDescriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get wizardDescriptionLabel;

  /// No description provided for @wizardBedroomsCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الغرف'**
  String get wizardBedroomsCount;

  /// No description provided for @wizardBathroomsCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الحمامات'**
  String get wizardBathroomsCount;

  /// No description provided for @wizardDragMapHint.
  ///
  /// In ar, this message translates to:
  /// **'اسحب الخريطة وحدد الموقع بدقة'**
  String get wizardDragMapHint;

  /// No description provided for @wizardConfirmLocation.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الموقع'**
  String get wizardConfirmLocation;

  /// No description provided for @wizardLandmarkLabel.
  ///
  /// In ar, this message translates to:
  /// **'أقرب معلم (اختياري)'**
  String get wizardLandmarkLabel;

  /// No description provided for @wizardLandmarkHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: قرب جامع النور'**
  String get wizardLandmarkHint;

  /// No description provided for @wizardLocationRequired.
  ///
  /// In ar, this message translates to:
  /// **'حدد الموقع على الخريطة أولاً'**
  String get wizardLocationRequired;

  /// No description provided for @wizardSetCoverPhoto.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كصورة رئيسية'**
  String get wizardSetCoverPhoto;

  /// No description provided for @wizardPickFromGallery.
  ///
  /// In ar, this message translates to:
  /// **'اختر من المعرض'**
  String get wizardPickFromGallery;

  /// No description provided for @wizardTakePhoto.
  ///
  /// In ar, this message translates to:
  /// **'التقط صورة'**
  String get wizardTakePhoto;

  /// No description provided for @wizardPhotosCount.
  ///
  /// In ar, this message translates to:
  /// **'{count}/15 صور'**
  String wizardPhotosCount(int count);

  /// No description provided for @wizardPhotosMaxReached.
  ///
  /// In ar, this message translates to:
  /// **'وصلت إلى الحد الأقصى (15 صورة).'**
  String get wizardPhotosMaxReached;

  /// No description provided for @wizardPhotoDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الصورة.'**
  String get wizardPhotoDeleted;

  /// No description provided for @wizardPhotosRequired.
  ///
  /// In ar, this message translates to:
  /// **'أضف صورة واحدة على الأقل.'**
  String get wizardPhotosRequired;

  /// No description provided for @wizardPublishListing.
  ///
  /// In ar, this message translates to:
  /// **'نشر العقار'**
  String get wizardPublishListing;

  /// No description provided for @wizardModerationNotice.
  ///
  /// In ar, this message translates to:
  /// **'سيتم مراجعة عقارك خلال 24 ساعة'**
  String get wizardModerationNotice;

  /// No description provided for @wizardSuccessTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال عقارك للمراجعة'**
  String get wizardSuccessTitle;

  /// No description provided for @wizardSuccessViewListing.
  ///
  /// In ar, this message translates to:
  /// **'عرض العقار'**
  String get wizardSuccessViewListing;

  /// No description provided for @wizardSuccessAddAnother.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عقار آخر'**
  String get wizardSuccessAddAnother;

  /// No description provided for @wizardPromotionEntry.
  ///
  /// In ar, this message translates to:
  /// **'تمييز هذا العقار'**
  String get wizardPromotionEntry;

  /// No description provided for @wizardPromotionComingSoonTitle.
  ///
  /// In ar, this message translates to:
  /// **'تمييز العقارات'**
  String get wizardPromotionComingSoonTitle;

  /// No description provided for @wizardPromotionComingSoonMessage.
  ///
  /// In ar, this message translates to:
  /// **'ميزة طلب التمييز ستتوفر قريباً. تواصل مع الدعم للاستفسار عن باقات التمييز.'**
  String get wizardPromotionComingSoonMessage;

  /// No description provided for @wizardQuotaTitle.
  ///
  /// In ar, this message translates to:
  /// **'وصلت إلى الحد الأقصى'**
  String get wizardQuotaTitle;

  /// No description provided for @wizardQuotaUpgradeCta.
  ///
  /// In ar, this message translates to:
  /// **'الترقية إلى مكتب عقاري'**
  String get wizardQuotaUpgradeCta;

  /// No description provided for @wizardQuotaUpgradeInfo.
  ///
  /// In ar, this message translates to:
  /// **'للترقية إلى حساب مكتب عقاري والحصول على حصة أكبر، تواصل مع الدعم.'**
  String get wizardQuotaUpgradeInfo;

  /// No description provided for @wizardExitConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'الخروج من المعالج'**
  String get wizardExitConfirmTitle;

  /// No description provided for @wizardExitConfirmMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ عقارك كمسودة، ويمكنك إكماله لاحقاً من عقاراتي.'**
  String get wizardExitConfirmMessage;

  /// No description provided for @wizardExitConfirmContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة التعديل'**
  String get wizardExitConfirmContinue;

  /// No description provided for @wizardExitConfirmExit.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get wizardExitConfirmExit;

  /// No description provided for @locationPickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر موقع العقار'**
  String get locationPickerTitle;

  /// No description provided for @searchPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن عقار أو موقع'**
  String get searchPlaceholder;

  /// No description provided for @searchRecentTitle.
  ///
  /// In ar, this message translates to:
  /// **'عمليات بحث سابقة'**
  String get searchRecentTitle;

  /// No description provided for @searchRecentClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح الكل'**
  String get searchRecentClear;

  /// No description provided for @filterTitle.
  ///
  /// In ar, this message translates to:
  /// **'البحث والتصفية'**
  String get filterTitle;

  /// No description provided for @filterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get filterAll;

  /// No description provided for @filterPropertyType.
  ///
  /// In ar, this message translates to:
  /// **'نوع العقار'**
  String get filterPropertyType;

  /// No description provided for @filterNeighborhood.
  ///
  /// In ar, this message translates to:
  /// **'الحي'**
  String get filterNeighborhood;

  /// No description provided for @filterPrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get filterPrice;

  /// No description provided for @filterPriceFrom.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get filterPriceFrom;

  /// No description provided for @filterPriceTo.
  ///
  /// In ar, this message translates to:
  /// **'إلى'**
  String get filterPriceTo;

  /// No description provided for @filterArea.
  ///
  /// In ar, this message translates to:
  /// **'المساحة'**
  String get filterArea;

  /// No description provided for @filterBedroomsLabel.
  ///
  /// In ar, this message translates to:
  /// **'عدد الغرف'**
  String get filterBedroomsLabel;

  /// No description provided for @filterBedroomsAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get filterBedroomsAll;

  /// No description provided for @filterBedrooms5Plus.
  ///
  /// In ar, this message translates to:
  /// **'+5'**
  String get filterBedrooms5Plus;

  /// Apply-filters button label with a live result count
  ///
  /// In ar, this message translates to:
  /// **'عرض النتائج ({count})'**
  String filterShowResults(int count);

  /// No description provided for @filterReset.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين'**
  String get filterReset;

  /// No description provided for @mapEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عقارات في هذه المنطقة'**
  String get mapEmptyTitle;

  /// No description provided for @mapEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'جرّب توسيع نطاق البحث'**
  String get mapEmptyMessage;

  /// No description provided for @mapViewToggleMap.
  ///
  /// In ar, this message translates to:
  /// **'الخريطة'**
  String get mapViewToggleMap;

  /// No description provided for @mapViewToggleList.
  ///
  /// In ar, this message translates to:
  /// **'القائمة'**
  String get mapViewToggleList;

  /// No description provided for @mapSearchThisArea.
  ///
  /// In ar, this message translates to:
  /// **'البحث في هذه المنطقة'**
  String get mapSearchThisArea;

  /// No description provided for @mapMarkersTruncated.
  ///
  /// In ar, this message translates to:
  /// **'تُعرض أقرب 500 نتيجة فقط. صغّر نطاق البحث لرؤية المزيد.'**
  String get mapMarkersTruncated;

  /// No description provided for @listingPropertyInfo.
  ///
  /// In ar, this message translates to:
  /// **'معلومات العقار'**
  String get listingPropertyInfo;

  /// No description provided for @listingNegotiable.
  ///
  /// In ar, this message translates to:
  /// **'قابل للتفاوض'**
  String get listingNegotiable;

  /// No description provided for @listingWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get listingWhatsapp;

  /// No description provided for @listingCall.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get listingCall;

  /// No description provided for @listingReport.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن هذا العقار'**
  String get listingReport;

  /// No description provided for @listingSimilar.
  ///
  /// In ar, this message translates to:
  /// **'عقارات مشابهة'**
  String get listingSimilar;

  /// Owner block "member since" line
  ///
  /// In ar, this message translates to:
  /// **'عضو منذ {date}'**
  String listingMemberSince(String date);

  /// No description provided for @listingGalleryEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد صور لهذا العقار'**
  String get listingGalleryEmpty;

  /// No description provided for @commonShare.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get commonShare;

  /// No description provided for @commonMore.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get commonMore;

  /// No description provided for @reportSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن هذا العقار'**
  String get reportSheetTitle;

  /// No description provided for @reportReasonLabel.
  ///
  /// In ar, this message translates to:
  /// **'سبب البلاغ'**
  String get reportReasonLabel;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In ar, this message translates to:
  /// **'محتوى غير لائق'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonMisleading.
  ///
  /// In ar, this message translates to:
  /// **'معلومات غير صحيحة'**
  String get reportReasonMisleading;

  /// No description provided for @reportReasonDuplicate.
  ///
  /// In ar, this message translates to:
  /// **'إعلان مكرر'**
  String get reportReasonDuplicate;

  /// No description provided for @reportReasonFraud.
  ///
  /// In ar, this message translates to:
  /// **'عملية احتيال'**
  String get reportReasonFraud;

  /// No description provided for @reportReasonOther.
  ///
  /// In ar, this message translates to:
  /// **'سبب آخر'**
  String get reportReasonOther;

  /// No description provided for @reportNoteLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختياري)'**
  String get reportNoteLabel;

  /// No description provided for @reportSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال البلاغ'**
  String get reportSubmit;

  /// No description provided for @reportSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال البلاغ.'**
  String get reportSubmitted;

  /// Share sheet caption for a listing deep link
  ///
  /// In ar, this message translates to:
  /// **'{title} على الباب العقاري: {url}'**
  String shareCaption(String title, String url);

  /// Prefilled WhatsApp message naming the listing title and price
  ///
  /// In ar, this message translates to:
  /// **'مرحباً، أنا مهتم بهذا العقار: {title} - {price}'**
  String contactWhatsappMessage(String title, String price);

  /// No description provided for @contactLaunchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح التطبيق المطلوب.'**
  String get contactLaunchFailed;

  /// No description provided for @accountMyListings.
  ///
  /// In ar, this message translates to:
  /// **'عقاراتي'**
  String get accountMyListings;

  /// No description provided for @accountFavorites.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة'**
  String get accountFavorites;

  /// No description provided for @accountMessages.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل'**
  String get accountMessages;

  /// No description provided for @accountNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get accountNotifications;

  /// No description provided for @accountStats.
  ///
  /// In ar, this message translates to:
  /// **'إحصائيات مشاهدات عقاراتي'**
  String get accountStats;

  /// No description provided for @accountSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get accountSettings;

  /// No description provided for @accountMarkAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكل كمقروء'**
  String get accountMarkAllRead;

  /// No description provided for @myListingsStatusAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get myListingsStatusAll;

  /// No description provided for @myListingsStatusPublished.
  ///
  /// In ar, this message translates to:
  /// **'منشور'**
  String get myListingsStatusPublished;

  /// No description provided for @myListingsStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get myListingsStatusPending;

  /// No description provided for @myListingsStatusRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get myListingsStatusRejected;

  /// No description provided for @myListingsStatusSoldRented.
  ///
  /// In ar, this message translates to:
  /// **'مباع/مؤجر'**
  String get myListingsStatusSoldRented;

  /// No description provided for @myListingsActionEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get myListingsActionEdit;

  /// No description provided for @myListingsActionPromote.
  ///
  /// In ar, this message translates to:
  /// **'تمييز'**
  String get myListingsActionPromote;

  /// No description provided for @myListingsActionPause.
  ///
  /// In ar, this message translates to:
  /// **'تعليق'**
  String get myListingsActionPause;

  /// No description provided for @myListingsActionDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get myListingsActionDelete;

  /// No description provided for @dashKpiTotalUsers.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المستخدمين'**
  String get dashKpiTotalUsers;

  /// No description provided for @dashKpiTotalListings.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي العقارات'**
  String get dashKpiTotalListings;

  /// No description provided for @dashKpiForSale.
  ///
  /// In ar, this message translates to:
  /// **'عقارات للبيع'**
  String get dashKpiForSale;

  /// No description provided for @dashKpiForRent.
  ///
  /// In ar, this message translates to:
  /// **'عقارات للإيجار'**
  String get dashKpiForRent;

  /// No description provided for @dashVisitsLast30Days.
  ///
  /// In ar, this message translates to:
  /// **'الزيارات خلال آخر 30 يوم'**
  String get dashVisitsLast30Days;

  /// No description provided for @dashListingsByType.
  ///
  /// In ar, this message translates to:
  /// **'العقارات حسب النوع'**
  String get dashListingsByType;

  /// No description provided for @dashLatestListings.
  ///
  /// In ar, this message translates to:
  /// **'أحدث العقارات المضافة'**
  String get dashLatestListings;

  /// No description provided for @dashMostViewed.
  ///
  /// In ar, this message translates to:
  /// **'أكثر العقارات مشاهدة'**
  String get dashMostViewed;

  /// No description provided for @dashKpiDelta.
  ///
  /// In ar, this message translates to:
  /// **'+{count} خلال 30 يوم'**
  String dashKpiDelta(int count);

  /// No description provided for @dashLoginTitle.
  ///
  /// In ar, this message translates to:
  /// **'دخول لوحة التحكم'**
  String get dashLoginTitle;

  /// No description provided for @dashLoginAdminOnlyError.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب غير مخوّل بالدخول إلى لوحة التحكم.'**
  String get dashLoginAdminOnlyError;

  /// No description provided for @dashModerationQueueTitle.
  ///
  /// In ar, this message translates to:
  /// **'طابور المراجعة'**
  String get dashModerationQueueTitle;

  /// No description provided for @dashStatusFilterLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get dashStatusFilterLabel;

  /// No description provided for @dashStatusFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'كل الحالات'**
  String get dashStatusFilterAll;

  /// No description provided for @dashApprove.
  ///
  /// In ar, this message translates to:
  /// **'موافقة'**
  String get dashApprove;

  /// No description provided for @dashReject.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get dashReject;

  /// No description provided for @dashRejectReasonLabel.
  ///
  /// In ar, this message translates to:
  /// **'سبب الرفض'**
  String get dashRejectReasonLabel;

  /// No description provided for @dashRejectReasonRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل سبب الرفض'**
  String get dashRejectReasonRequired;

  /// No description provided for @dashApproved.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة على العقار.'**
  String get dashApproved;

  /// No description provided for @dashRejected.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض العقار.'**
  String get dashRejected;

  /// No description provided for @dashColTitle.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get dashColTitle;

  /// No description provided for @dashColNeighborhood.
  ///
  /// In ar, this message translates to:
  /// **'الحي'**
  String get dashColNeighborhood;

  /// No description provided for @dashColPrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get dashColPrice;

  /// No description provided for @dashColStatus.
  ///
  /// In ar, this message translates to:
  /// **'الحالة'**
  String get dashColStatus;

  /// No description provided for @dashColDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get dashColDate;

  /// No description provided for @dashColViews.
  ///
  /// In ar, this message translates to:
  /// **'المشاهدات'**
  String get dashColViews;

  /// No description provided for @dashColActions.
  ///
  /// In ar, this message translates to:
  /// **'الإجراءات'**
  String get dashColActions;

  /// No description provided for @dashEmptyListingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عقارات'**
  String get dashEmptyListingsTitle;

  /// No description provided for @dashEmptyListingsMessage.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عقارات مطابقة لهذا الفلتر.'**
  String get dashEmptyListingsMessage;

  /// No description provided for @dashColListing.
  ///
  /// In ar, this message translates to:
  /// **'العقار'**
  String get dashColListing;

  /// No description provided for @dashColReporter.
  ///
  /// In ar, this message translates to:
  /// **'المُبلّغ'**
  String get dashColReporter;

  /// No description provided for @dashColReason.
  ///
  /// In ar, this message translates to:
  /// **'السبب'**
  String get dashColReason;

  /// No description provided for @dashColNote.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة'**
  String get dashColNote;

  /// No description provided for @dashReportStatusOpen.
  ///
  /// In ar, this message translates to:
  /// **'مفتوح'**
  String get dashReportStatusOpen;

  /// No description provided for @dashReportStatusClosed.
  ///
  /// In ar, this message translates to:
  /// **'مغلق'**
  String get dashReportStatusClosed;

  /// No description provided for @dashReportClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق البلاغ'**
  String get dashReportClose;

  /// No description provided for @dashReportClosed.
  ///
  /// In ar, this message translates to:
  /// **'تم إغلاق البلاغ.'**
  String get dashReportClosed;

  /// No description provided for @dashEmptyReportsTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بلاغات'**
  String get dashEmptyReportsTitle;

  /// No description provided for @dashEmptyReportsMessage.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بلاغات مطابقة لهذا الفلتر.'**
  String get dashEmptyReportsMessage;

  /// No description provided for @dashExportListingsCsv.
  ///
  /// In ar, this message translates to:
  /// **'تصدير العقارات (CSV)'**
  String get dashExportListingsCsv;

  /// No description provided for @dashExportUsersCsv.
  ///
  /// In ar, this message translates to:
  /// **'تصدير المستخدمين (CSV)'**
  String get dashExportUsersCsv;

  /// No description provided for @dashExportDone.
  ///
  /// In ar, this message translates to:
  /// **'تم تنزيل الملف.'**
  String get dashExportDone;

  /// No description provided for @dashSettingsNeighborhoods.
  ///
  /// In ar, this message translates to:
  /// **'الأحياء'**
  String get dashSettingsNeighborhoods;

  /// No description provided for @dashSettingsQuotas.
  ///
  /// In ar, this message translates to:
  /// **'الحصص'**
  String get dashSettingsQuotas;

  /// No description provided for @dashSettingsPages.
  ///
  /// In ar, this message translates to:
  /// **'المحتوى الثابت'**
  String get dashSettingsPages;

  /// No description provided for @dashColNameAr.
  ///
  /// In ar, this message translates to:
  /// **'الاسم (عربي)'**
  String get dashColNameAr;

  /// No description provided for @dashColNameEn.
  ///
  /// In ar, this message translates to:
  /// **'الاسم (إنجليزي)'**
  String get dashColNameEn;

  /// No description provided for @dashColSlug.
  ///
  /// In ar, this message translates to:
  /// **'المعرف'**
  String get dashColSlug;

  /// No description provided for @dashColLat.
  ///
  /// In ar, this message translates to:
  /// **'خط العرض'**
  String get dashColLat;

  /// No description provided for @dashColLng.
  ///
  /// In ar, this message translates to:
  /// **'خط الطول'**
  String get dashColLng;

  /// No description provided for @dashColActive.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل'**
  String get dashColActive;

  /// No description provided for @dashActive.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل'**
  String get dashActive;

  /// No description provided for @dashInactive.
  ///
  /// In ar, this message translates to:
  /// **'غير مفعّل'**
  String get dashInactive;

  /// No description provided for @dashAddNeighborhood.
  ///
  /// In ar, this message translates to:
  /// **'إضافة حي'**
  String get dashAddNeighborhood;

  /// No description provided for @dashEditNeighborhood.
  ///
  /// In ar, this message translates to:
  /// **'تعديل حي'**
  String get dashEditNeighborhood;

  /// No description provided for @dashNeighborhoodSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الحي.'**
  String get dashNeighborhoodSaved;

  /// No description provided for @dashNeighborhoodDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الحي.'**
  String get dashNeighborhoodDeleted;

  /// No description provided for @dashNeighborhoodNameArLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم (عربي)'**
  String get dashNeighborhoodNameArLabel;

  /// No description provided for @dashNeighborhoodNameEnLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم (إنجليزي)'**
  String get dashNeighborhoodNameEnLabel;

  /// No description provided for @dashNeighborhoodSlugLabel.
  ///
  /// In ar, this message translates to:
  /// **'المعرف (slug)'**
  String get dashNeighborhoodSlugLabel;

  /// No description provided for @dashNeighborhoodLatLabel.
  ///
  /// In ar, this message translates to:
  /// **'خط العرض (Latitude)'**
  String get dashNeighborhoodLatLabel;

  /// No description provided for @dashNeighborhoodLngLabel.
  ///
  /// In ar, this message translates to:
  /// **'خط الطول (Longitude)'**
  String get dashNeighborhoodLngLabel;

  /// No description provided for @dashNeighborhoodActiveLabel.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل'**
  String get dashNeighborhoodActiveLabel;

  /// No description provided for @dashEmptyNeighborhoodsTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أحياء'**
  String get dashEmptyNeighborhoodsTitle;

  /// No description provided for @dashEmptyNeighborhoodsMessage.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم إضافة أي حي بعد.'**
  String get dashEmptyNeighborhoodsMessage;

  /// No description provided for @dashConfirmDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get dashConfirmDeleteTitle;

  /// No description provided for @dashConfirmDeleteNeighborhoodMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذا الحي؟'**
  String get dashConfirmDeleteNeighborhoodMessage;

  /// No description provided for @dashQuotaSeeker.
  ///
  /// In ar, this message translates to:
  /// **'الباحث عن عقار'**
  String get dashQuotaSeeker;

  /// No description provided for @dashQuotaOwner.
  ///
  /// In ar, this message translates to:
  /// **'مالك عقار'**
  String get dashQuotaOwner;

  /// No description provided for @dashQuotaAgency.
  ///
  /// In ar, this message translates to:
  /// **'مكتب عقاري'**
  String get dashQuotaAgency;

  /// No description provided for @dashQuotasHint.
  ///
  /// In ar, this message translates to:
  /// **'الحد الأقصى لعدد العقارات النشطة لكل دور.'**
  String get dashQuotasHint;

  /// No description provided for @dashQuotasSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الحصص.'**
  String get dashQuotasSaved;

  /// No description provided for @dashAddPage.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صفحة'**
  String get dashAddPage;

  /// No description provided for @dashEditPage.
  ///
  /// In ar, this message translates to:
  /// **'تعديل صفحة'**
  String get dashEditPage;

  /// No description provided for @dashPageSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الصفحة.'**
  String get dashPageSaved;

  /// No description provided for @dashPageDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الصفحة.'**
  String get dashPageDeleted;

  /// No description provided for @dashPageSlugLabel.
  ///
  /// In ar, this message translates to:
  /// **'المعرف (slug)'**
  String get dashPageSlugLabel;

  /// No description provided for @dashPageTitleArLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان (عربي)'**
  String get dashPageTitleArLabel;

  /// No description provided for @dashPageTitleEnLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان (إنجليزي)'**
  String get dashPageTitleEnLabel;

  /// No description provided for @dashPageBodyArLabel.
  ///
  /// In ar, this message translates to:
  /// **'المحتوى (عربي)'**
  String get dashPageBodyArLabel;

  /// No description provided for @dashPageBodyEnLabel.
  ///
  /// In ar, this message translates to:
  /// **'المحتوى (إنجليزي)'**
  String get dashPageBodyEnLabel;

  /// No description provided for @dashEmptyPagesTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد محتوى'**
  String get dashEmptyPagesTitle;

  /// No description provided for @dashEmptyPagesMessage.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة أي صفحة بعد.'**
  String get dashEmptyPagesMessage;

  /// No description provided for @dashPromotionsPackagesTab.
  ///
  /// In ar, this message translates to:
  /// **'الباقات'**
  String get dashPromotionsPackagesTab;

  /// No description provided for @dashPromotionsActiveTab.
  ///
  /// In ar, this message translates to:
  /// **'الإعلانات'**
  String get dashPromotionsActiveTab;

  /// No description provided for @dashAddPackage.
  ///
  /// In ar, this message translates to:
  /// **'إضافة باقة'**
  String get dashAddPackage;

  /// No description provided for @dashEditPackage.
  ///
  /// In ar, this message translates to:
  /// **'تعديل باقة'**
  String get dashEditPackage;

  /// No description provided for @dashPackageSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الباقة.'**
  String get dashPackageSaved;

  /// No description provided for @dashPackageDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الباقة.'**
  String get dashPackageDeleted;

  /// No description provided for @dashPackageNameArLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم (عربي)'**
  String get dashPackageNameArLabel;

  /// No description provided for @dashPackageNameEnLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم (إنجليزي)'**
  String get dashPackageNameEnLabel;

  /// No description provided for @dashPackageDaysLabel.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأيام'**
  String get dashPackageDaysLabel;

  /// No description provided for @dashPackagePriceLabel.
  ///
  /// In ar, this message translates to:
  /// **'السعر (USD)'**
  String get dashPackagePriceLabel;

  /// No description provided for @dashPackageActiveLabel.
  ///
  /// In ar, this message translates to:
  /// **'مفعّلة'**
  String get dashPackageActiveLabel;

  /// No description provided for @dashColDays.
  ///
  /// In ar, this message translates to:
  /// **'عدد الأيام'**
  String get dashColDays;

  /// No description provided for @dashEmptyPackagesTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد باقات'**
  String get dashEmptyPackagesTitle;

  /// No description provided for @dashEmptyPackagesMessage.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة أي باقة بعد.'**
  String get dashEmptyPackagesMessage;

  /// No description provided for @dashConfirmDeletePackageMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف هذه الباقة؟'**
  String get dashConfirmDeletePackageMessage;

  /// No description provided for @dashAddPromotion.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء إعلان'**
  String get dashAddPromotion;

  /// No description provided for @dashPromotionListingIdLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم العقار'**
  String get dashPromotionListingIdLabel;

  /// No description provided for @dashPromotionPackageLabel.
  ///
  /// In ar, this message translates to:
  /// **'الباقة'**
  String get dashPromotionPackageLabel;

  /// No description provided for @dashPromotionCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الإعلان.'**
  String get dashPromotionCreated;

  /// No description provided for @dashColOwner.
  ///
  /// In ar, this message translates to:
  /// **'المالك'**
  String get dashColOwner;

  /// No description provided for @dashColPackage.
  ///
  /// In ar, this message translates to:
  /// **'الباقة'**
  String get dashColPackage;

  /// No description provided for @dashColDaysRemaining.
  ///
  /// In ar, this message translates to:
  /// **'الأيام المتبقية'**
  String get dashColDaysRemaining;

  /// No description provided for @dashStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get dashStatusPending;

  /// No description provided for @dashPromotionStatusActive.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get dashPromotionStatusActive;

  /// No description provided for @dashPromotionStatusExpired.
  ///
  /// In ar, this message translates to:
  /// **'منتهي'**
  String get dashPromotionStatusExpired;

  /// No description provided for @dashEmptyPromotionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إعلانات'**
  String get dashEmptyPromotionsTitle;

  /// No description provided for @dashEmptyPromotionsMessage.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إعلانات مطابقة لهذا الفلتر.'**
  String get dashEmptyPromotionsMessage;

  /// No description provided for @dashRecordPayment.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل دفعة'**
  String get dashRecordPayment;

  /// No description provided for @dashTransactionPromotionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإعلان المعلّق'**
  String get dashTransactionPromotionLabel;

  /// No description provided for @dashTransactionAmountLabel.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get dashTransactionAmountLabel;

  /// No description provided for @dashTransactionMethodLabel.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get dashTransactionMethodLabel;

  /// No description provided for @dashTransactionMethodCash.
  ///
  /// In ar, this message translates to:
  /// **'نقداً'**
  String get dashTransactionMethodCash;

  /// No description provided for @dashTransactionMethodManual.
  ///
  /// In ar, this message translates to:
  /// **'يدوي'**
  String get dashTransactionMethodManual;

  /// No description provided for @dashTransactionCurrencyLabel.
  ///
  /// In ar, this message translates to:
  /// **'العملة'**
  String get dashTransactionCurrencyLabel;

  /// No description provided for @dashTransactionReferenceLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم مرجعي (اختياري)'**
  String get dashTransactionReferenceLabel;

  /// No description provided for @dashTransactionRecorded.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدفعة.'**
  String get dashTransactionRecorded;

  /// No description provided for @dashTransactionStatusCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get dashTransactionStatusCompleted;

  /// No description provided for @dashColMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get dashColMethod;

  /// No description provided for @dashColAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get dashColAmount;

  /// No description provided for @dashColReference.
  ///
  /// In ar, this message translates to:
  /// **'المرجع'**
  String get dashColReference;

  /// No description provided for @dashFilterDateFrom.
  ///
  /// In ar, this message translates to:
  /// **'من تاريخ'**
  String get dashFilterDateFrom;

  /// No description provided for @dashFilterDateTo.
  ///
  /// In ar, this message translates to:
  /// **'إلى تاريخ'**
  String get dashFilterDateTo;

  /// No description provided for @dashEmptyTransactionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد معاملات'**
  String get dashEmptyTransactionsTitle;

  /// No description provided for @dashEmptyTransactionsMessage.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد معاملات مطابقة لهذا الفلتر.'**
  String get dashEmptyTransactionsMessage;

  /// No description provided for @dashNoPendingPromotions.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إعلانات معلّقة لتحصيلها.'**
  String get dashNoPendingPromotions;

  /// No description provided for @dashNotificationTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get dashNotificationTitleLabel;

  /// No description provided for @dashNotificationBodyLabel.
  ///
  /// In ar, this message translates to:
  /// **'النص'**
  String get dashNotificationBodyLabel;

  /// No description provided for @dashNotificationTargetLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإرسال إلى'**
  String get dashNotificationTargetLabel;

  /// No description provided for @dashNotificationTargetAll.
  ///
  /// In ar, this message translates to:
  /// **'كل المستخدمين'**
  String get dashNotificationTargetAll;

  /// No description provided for @dashNotificationTargetRole.
  ///
  /// In ar, this message translates to:
  /// **'حسب الدور'**
  String get dashNotificationTargetRole;

  /// No description provided for @dashNotificationTargetUser.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم واحد'**
  String get dashNotificationTargetUser;

  /// No description provided for @dashNotificationRoleLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get dashNotificationRoleLabel;

  /// No description provided for @dashNotificationUserLabel.
  ///
  /// In ar, this message translates to:
  /// **'المستخدم'**
  String get dashNotificationUserLabel;

  /// No description provided for @dashSendBroadcast.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get dashSendBroadcast;

  /// No description provided for @dashBroadcastSent.
  ///
  /// In ar, this message translates to:
  /// **'تم الإرسال إلى {count} {count, plural, =1{مستخدم} =2{مستخدمين} few{مستخدمين} other{مستخدم}}.'**
  String dashBroadcastSent(int count);

  /// No description provided for @dashNotificationPreviewLabel.
  ///
  /// In ar, this message translates to:
  /// **'معاينة'**
  String get dashNotificationPreviewLabel;

  /// No description provided for @dashNotificationPreviewEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الإشعار'**
  String get dashNotificationPreviewEmptyTitle;

  /// No description provided for @dashNotificationPreviewEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'سيظهر نص الإشعار هنا.'**
  String get dashNotificationPreviewEmptyBody;

  /// No description provided for @dashSidebarCollapse.
  ///
  /// In ar, this message translates to:
  /// **'طي القائمة'**
  String get dashSidebarCollapse;

  /// No description provided for @dash404Title.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة غير موجودة'**
  String get dash404Title;

  /// No description provided for @dash404Message.
  ///
  /// In ar, this message translates to:
  /// **'الرابط الذي حاولت الوصول إليه غير موجود.'**
  String get dash404Message;

  /// No description provided for @dash404GoHome.
  ///
  /// In ar, this message translates to:
  /// **'العودة للرئيسية'**
  String get dash404GoHome;

  /// No description provided for @dashSearchPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'بحث...'**
  String get dashSearchPlaceholder;

  /// No description provided for @dashRoleFilterLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get dashRoleFilterLabel;

  /// No description provided for @dashRoleFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'كل الأدوار'**
  String get dashRoleFilterAll;

  /// No description provided for @dashColPhone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get dashColPhone;

  /// No description provided for @dashColRole.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get dashColRole;

  /// No description provided for @dashUserStatusActive.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get dashUserStatusActive;

  /// No description provided for @dashUserStatusBlocked.
  ///
  /// In ar, this message translates to:
  /// **'محظور'**
  String get dashUserStatusBlocked;

  /// No description provided for @dashUserDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيانات المستخدم'**
  String get dashUserDetailsTitle;

  /// No description provided for @dashUserBlock.
  ///
  /// In ar, this message translates to:
  /// **'حظر'**
  String get dashUserBlock;

  /// No description provided for @dashUserUnblock.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحظر'**
  String get dashUserUnblock;

  /// No description provided for @dashUserBlockReasonLabel.
  ///
  /// In ar, this message translates to:
  /// **'سبب الحظر'**
  String get dashUserBlockReasonLabel;

  /// No description provided for @dashUserBlockReasonRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل سبب الحظر'**
  String get dashUserBlockReasonRequired;

  /// No description provided for @dashUserBlocked.
  ///
  /// In ar, this message translates to:
  /// **'تم حظر المستخدم.'**
  String get dashUserBlocked;

  /// No description provided for @dashUserUnblocked.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء حظر المستخدم.'**
  String get dashUserUnblocked;

  /// No description provided for @dashChangeRoleLabel.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الدور'**
  String get dashChangeRoleLabel;

  /// No description provided for @dashUserRoleChanged.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الدور.'**
  String get dashUserRoleChanged;

  /// No description provided for @dashUserListingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'العقارات'**
  String get dashUserListingsTitle;

  /// No description provided for @dashUserBlockedReason.
  ///
  /// In ar, this message translates to:
  /// **'محظور — {reason}'**
  String dashUserBlockedReason(String reason);

  /// No description provided for @dashEmptyUsersTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مستخدمون'**
  String get dashEmptyUsersTitle;

  /// No description provided for @dashEmptyUsersMessage.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مستخدمون مطابقون لهذا الفلتر.'**
  String get dashEmptyUsersMessage;

  /// No description provided for @commonClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get commonClose;

  /// No description provided for @emptyStateDefaultTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد شيء هنا بعد'**
  String get emptyStateDefaultTitle;

  /// No description provided for @errorStateDefaultTitle.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ ما'**
  String get errorStateDefaultTitle;

  /// No description provided for @errorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In ar, this message translates to:
  /// **'انتهت مهلة الاتصال بالخادم.'**
  String get errorTimeout;

  /// No description provided for @errorUnauthorized.
  ///
  /// In ar, this message translates to:
  /// **'يجب تسجيل الدخول لإتمام هذا الإجراء.'**
  String get errorUnauthorized;

  /// No description provided for @errorUnknown.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع.'**
  String get errorUnknown;

  /// No description provided for @statsAreaLabel.
  ///
  /// In ar, this message translates to:
  /// **'المساحة'**
  String get statsAreaLabel;

  /// No description provided for @statsBedroomsLabel.
  ///
  /// In ar, this message translates to:
  /// **'غرف النوم'**
  String get statsBedroomsLabel;

  /// No description provided for @statsBathroomsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحمامات'**
  String get statsBathroomsLabel;

  /// Formatted area in square meters
  ///
  /// In ar, this message translates to:
  /// **'{value} م²'**
  String areaUnit(String value);

  /// No description provided for @relativeTimeJustNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get relativeTimeJustNow;

  /// No description provided for @relativeTimeMinutesAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} {count, plural, =1{دقيقة} =2{دقيقتين} few{دقائق} other{دقيقة}}'**
  String relativeTimeMinutesAgo(int count);

  /// No description provided for @relativeTimeHoursAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} {count, plural, =1{ساعة} =2{ساعتين} few{ساعات} other{ساعة}}'**
  String relativeTimeHoursAgo(int count);

  /// No description provided for @relativeTimeDaysAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} {count, plural, =1{يوم} =2{يومين} few{أيام} other{يوم}}'**
  String relativeTimeDaysAgo(int count);

  /// No description provided for @relativeTimeWeeksAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} {count, plural, =1{أسبوع} =2{أسبوعين} few{أسابيع} other{أسبوع}}'**
  String relativeTimeWeeksAgo(int count);

  /// No description provided for @relativeTimeMonthsAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} {count, plural, =1{شهر} =2{شهرين} few{أشهر} other{شهر}}'**
  String relativeTimeMonthsAgo(int count);

  /// No description provided for @relativeTimeYearsAgo.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} {count, plural, =1{سنة} =2{سنتين} few{سنوات} other{سنة}}'**
  String relativeTimeYearsAgo(int count);

  /// No description provided for @accountGuestPromptTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول للوصول إلى حسابك'**
  String get accountGuestPromptTitle;

  /// No description provided for @accountGuestPromptMessage.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة والرسائل والإشعارات وإضافة العقارات تحتاج إلى حساب.'**
  String get accountGuestPromptMessage;

  /// No description provided for @myListingsEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عقارات بعد'**
  String get myListingsEmptyTitle;

  /// No description provided for @myListingsEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'عقاراتك المنشورة وقيد المراجعة تظهر هنا.'**
  String get myListingsEmptyMessage;

  /// No description provided for @myListingsDeleteConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف العقار؟'**
  String get myListingsDeleteConfirmTitle;

  /// No description provided for @myListingsDeleteConfirmMessage.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن التراجع عن هذا الإجراء.'**
  String get myListingsDeleteConfirmMessage;

  /// No description provided for @myListingsActionRepublish.
  ///
  /// In ar, this message translates to:
  /// **'إعادة النشر'**
  String get myListingsActionRepublish;

  /// No description provided for @myListingsRejectionReasonLabel.
  ///
  /// In ar, this message translates to:
  /// **'سبب الرفض'**
  String get myListingsRejectionReasonLabel;

  /// No description provided for @myListingsViewsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} مشاهدة'**
  String myListingsViewsCount(int count);

  /// No description provided for @myListingsDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف العقار'**
  String get myListingsDeleted;

  /// No description provided for @myListingsStatusUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث حالة العقار'**
  String get myListingsStatusUpdated;

  /// No description provided for @statsLast30Days.
  ///
  /// In ar, this message translates to:
  /// **'آخر 30 يوماً'**
  String get statsLast30Days;

  /// No description provided for @statsTotalViews.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المشاهدات'**
  String get statsTotalViews;

  /// No description provided for @statsTotalContacts.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي التواصل'**
  String get statsTotalContacts;

  /// No description provided for @statsByChannelTitle.
  ///
  /// In ar, this message translates to:
  /// **'التواصل حسب القناة'**
  String get statsByChannelTitle;

  /// No description provided for @statsChannelMessage.
  ///
  /// In ar, this message translates to:
  /// **'رسالة'**
  String get statsChannelMessage;

  /// No description provided for @statsPerListingTitle.
  ///
  /// In ar, this message translates to:
  /// **'أداء كل عقار'**
  String get statsPerListingTitle;

  /// No description provided for @statsEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات مشاهدات بعد.'**
  String get statsEmptyMessage;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عقارات في المفضلة'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على أيقونة القلب في أي عقار لإضافته هنا.'**
  String get favoritesEmptyMessage;

  /// No description provided for @favoritesRemoved.
  ///
  /// In ar, this message translates to:
  /// **'تمت الإزالة من المفضلة'**
  String get favoritesRemoved;

  /// No description provided for @favoriteAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إلى المفضلة'**
  String get favoriteAdd;

  /// No description provided for @favoriteRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من المفضلة'**
  String get favoriteRemove;

  /// No description provided for @connectivityOffline.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get connectivityOffline;

  /// No description provided for @paginationLoadMoreFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المزيد، إعادة المحاولة'**
  String get paginationLoadMoreFailed;

  /// No description provided for @mapMarkersRefreshFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث النتائج — يتم عرض آخر نتائج محفوظة'**
  String get mapMarkersRefreshFailed;

  /// No description provided for @messagesEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رسائل بعد'**
  String get messagesEmptyTitle;

  /// No description provided for @messagesEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع مالك عقار لبدء محادثة.'**
  String get messagesEmptyMessage;

  /// No description provided for @messageInputHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالة...'**
  String get messageInputHint;

  /// No description provided for @messageSendFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إرسال الرسالة'**
  String get messageSendFailed;

  /// No description provided for @messagesConversationEmpty.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ المحادثة برسالة.'**
  String get messagesConversationEmpty;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر التحديثات المتعلقة بعقاراتك ورسائلك هنا.'**
  String get notificationsEmptyMessage;

  /// No description provided for @notificationsSectionToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get notificationsSectionToday;

  /// No description provided for @notificationsSectionYesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get notificationsSectionYesterday;

  /// No description provided for @notificationsSectionEarlier.
  ///
  /// In ar, this message translates to:
  /// **'سابقاً'**
  String get notificationsSectionEarlier;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get settingsLanguageArabic;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsPushToggleLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات الفورية'**
  String get settingsPushToggleLabel;

  /// No description provided for @settingsEditProfile.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف الشخصي'**
  String get settingsEditProfile;

  /// No description provided for @settingsChangeAvatar.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الصورة الشخصية'**
  String get settingsChangeAvatar;

  /// No description provided for @settingsChangePassword.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get settingsChangePassword;

  /// No description provided for @settingsAbout.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get settingsAbout;

  /// No description provided for @settingsAboutBody.
  ///
  /// In ar, this message translates to:
  /// **'الباب العقاري — منصة عقارية لمدينة الباب، سوريا.'**
  String get settingsAboutBody;

  /// No description provided for @settingsContactSupport.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع الدعم'**
  String get settingsContactSupport;

  /// No description provided for @settingsContactSupportMessage.
  ///
  /// In ar, this message translates to:
  /// **'لأي استفسار، تواصل معنا عبر واتساب.'**
  String get settingsContactSupportMessage;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب؟'**
  String get settingsDeleteAccountConfirmTitle;

  /// No description provided for @settingsDeleteAccountConfirmMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف حسابك وكل بياناتك نهائياً.'**
  String get settingsDeleteAccountConfirmMessage;

  /// No description provided for @settingsNotAvailableMessage.
  ///
  /// In ar, this message translates to:
  /// **'هذه الميزة غير متاحة حالياً — تواصل مع الدعم.'**
  String get settingsNotAvailableMessage;

  /// No description provided for @settingsVersionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get settingsVersionLabel;

  /// No description provided for @editProfileWhatsappLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم واتساب (اختياري)'**
  String get editProfileWhatsappLabel;

  /// No description provided for @editProfileSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ التغييرات'**
  String get editProfileSaved;

  /// No description provided for @editProfileChangePhoto.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الصورة'**
  String get editProfileChangePhoto;

  /// No description provided for @commonSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get commonSend;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

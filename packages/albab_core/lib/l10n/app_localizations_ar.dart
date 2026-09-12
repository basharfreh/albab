// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'الباب العقاري';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonAdd => 'إضافة';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonConfirm => 'تأكيد';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonNext => 'التالي';

  @override
  String get commonDone => 'تم';

  @override
  String get commonLoading => 'جارٍ التحميل...';

  @override
  String get commonViewAll => 'عرض الكل';

  @override
  String get commonUndo => 'تراجع';

  @override
  String get authLogin => 'تسجيل الدخول';

  @override
  String get authRegister => 'إنشاء حساب';

  @override
  String get authContinueAsGuest => 'متابعة كضيف';

  @override
  String get authLogout => 'تسجيل الخروج';

  @override
  String get authPhone => 'رقم الهاتف';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get authName => 'الاسم';

  @override
  String get authAgencyName => 'اسم المكتب';

  @override
  String get authWelcomeTagline => 'اعثر على منزلك القادم في الباب';

  @override
  String get authNoAccountPrompt => 'ليس لديك حساب؟';

  @override
  String get authHaveAccountPrompt => 'لديك حساب بالفعل؟';

  @override
  String get authChooseRole => 'نوع الحساب';

  @override
  String get authOtpTitle => 'تحقق من رقم الهاتف';

  @override
  String authOtpSubtitle(String phone) {
    return 'أدخل الرمز المرسل إلى $phone';
  }

  @override
  String authOtpDebugCode(String code) {
    return '(للتجربة) الرمز: $code';
  }

  @override
  String authOtpResendIn(int seconds) {
    return 'إعادة الإرسال خلال $seconds ثانية';
  }

  @override
  String get authOtpResend => 'إعادة إرسال الرمز';

  @override
  String get authOtpVerify => 'تحقق';

  @override
  String get authOtpVerified => 'تم التحقق من رقم الهاتف';

  @override
  String get authOtpSkip => 'تخطي الآن';

  @override
  String get authGuestGateTitle => 'سجّل الدخول للمتابعة';

  @override
  String get authGuestGateMessage =>
      'يلزم إنشاء حساب أو تسجيل الدخول لاستخدام هذه الميزة';

  @override
  String get validationRequired => 'هذا الحقل مطلوب';

  @override
  String get validationPhoneInvalid => 'رقم الهاتف غير صحيح';

  @override
  String get validationPasswordTooShort => 'كلمة المرور يجب ألا تقل عن 8 أحرف';

  @override
  String get validationOtpIncomplete => 'أدخل الرمز كاملاً';

  @override
  String get validationPriceInvalid => 'أدخل سعراً صحيحاً';

  @override
  String get roleSeeker => 'مستخدم';

  @override
  String get roleOwner => 'مالك عقار';

  @override
  String get roleAgency => 'مكتب عقاري';

  @override
  String get roleAdmin => 'مشرف';

  @override
  String get propertyTypeHouse => 'منزل';

  @override
  String get propertyTypeApartment => 'شقة';

  @override
  String get propertyTypeShop => 'محل';

  @override
  String get propertyTypeLand => 'أرض';

  @override
  String get propertyTypeOther => 'أخرى';

  @override
  String get purposeSale => 'للبيع';

  @override
  String get purposeRent => 'للإيجار';

  @override
  String get listingStatusDraft => 'مسودة';

  @override
  String get listingStatusPending => 'قيد المراجعة';

  @override
  String get listingStatusPublished => 'منشور';

  @override
  String get listingStatusRejected => 'مرفوض';

  @override
  String get listingStatusSold => 'مباع';

  @override
  String get listingStatusRented => 'مؤجر';

  @override
  String get listingStatusPaused => 'معلق';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navMessages => 'الرسائل';

  @override
  String get navAdd => 'أضف عقار';

  @override
  String get navFavorites => 'المفضلة';

  @override
  String get navAccount => 'الحساب';

  @override
  String get dashNavHome => 'الرئيسية';

  @override
  String get dashNavListings => 'العقارات';

  @override
  String get dashNavUsers => 'المستخدمين';

  @override
  String get dashNavPromotions => 'الإعلانات';

  @override
  String get dashNavTransactions => 'المعاملات';

  @override
  String get dashNavNotifications => 'الإشعارات';

  @override
  String get dashNavReports => 'التقارير';

  @override
  String get dashNavSettings => 'الإعدادات';

  @override
  String get wizardStepInfo => 'المعلومات';

  @override
  String get wizardStepLocation => 'الموقع';

  @override
  String get wizardStepPhotos => 'الصور';

  @override
  String get wizardStepReview => 'مراجعة';

  @override
  String get wizardTitleLabel => 'عنوان الإعلان';

  @override
  String get wizardTitleHint => 'مثال: منزل في حي الحسين';

  @override
  String get wizardPriceLabel => 'السعر';

  @override
  String get wizardNegotiable => 'قابل للتفاوض';

  @override
  String get wizardDescriptionLabel => 'الوصف';

  @override
  String get wizardBedroomsCount => 'عدد الغرف';

  @override
  String get wizardBathroomsCount => 'عدد الحمامات';

  @override
  String get wizardDragMapHint => 'اسحب الخريطة وحدد الموقع بدقة';

  @override
  String get wizardConfirmLocation => 'تأكيد الموقع';

  @override
  String get wizardLandmarkLabel => 'أقرب معلم (اختياري)';

  @override
  String get wizardLandmarkHint => 'مثال: قرب جامع النور';

  @override
  String get wizardLocationRequired => 'حدد الموقع على الخريطة أولاً';

  @override
  String get wizardSetCoverPhoto => 'تعيين كصورة رئيسية';

  @override
  String get wizardPickFromGallery => 'اختر من المعرض';

  @override
  String get wizardTakePhoto => 'التقط صورة';

  @override
  String wizardPhotosCount(int count) {
    return '$count/15 صور';
  }

  @override
  String get wizardPhotosMaxReached => 'وصلت إلى الحد الأقصى (15 صورة).';

  @override
  String get wizardPhotoDeleted => 'تم حذف الصورة.';

  @override
  String get wizardPhotosRequired => 'أضف صورة واحدة على الأقل.';

  @override
  String get wizardPublishListing => 'نشر العقار';

  @override
  String get wizardModerationNotice => 'سيتم مراجعة عقارك خلال 24 ساعة';

  @override
  String get wizardSuccessTitle => 'تم إرسال عقارك للمراجعة';

  @override
  String get wizardSuccessViewListing => 'عرض العقار';

  @override
  String get wizardSuccessAddAnother => 'إضافة عقار آخر';

  @override
  String get wizardPromotionEntry => 'تمييز هذا العقار';

  @override
  String get wizardPromotionComingSoonTitle => 'تمييز العقارات';

  @override
  String get wizardPromotionComingSoonMessage =>
      'ميزة طلب التمييز ستتوفر قريباً. تواصل مع الدعم للاستفسار عن باقات التمييز.';

  @override
  String get wizardQuotaTitle => 'وصلت إلى الحد الأقصى';

  @override
  String get wizardQuotaUpgradeCta => 'الترقية إلى مكتب عقاري';

  @override
  String get wizardQuotaUpgradeInfo =>
      'للترقية إلى حساب مكتب عقاري والحصول على حصة أكبر، تواصل مع الدعم.';

  @override
  String get wizardExitConfirmTitle => 'الخروج من المعالج';

  @override
  String get wizardExitConfirmMessage =>
      'تم حفظ عقارك كمسودة، ويمكنك إكماله لاحقاً من عقاراتي.';

  @override
  String get wizardExitConfirmContinue => 'متابعة التعديل';

  @override
  String get wizardExitConfirmExit => 'خروج';

  @override
  String get locationPickerTitle => 'اختر موقع العقار';

  @override
  String get searchPlaceholder => 'ابحث عن عقار أو موقع';

  @override
  String get searchRecentTitle => 'عمليات بحث سابقة';

  @override
  String get searchRecentClear => 'مسح الكل';

  @override
  String get filterTitle => 'البحث والتصفية';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterPropertyType => 'نوع العقار';

  @override
  String get filterNeighborhood => 'الحي';

  @override
  String get filterPrice => 'السعر';

  @override
  String get filterPriceFrom => 'من';

  @override
  String get filterPriceTo => 'إلى';

  @override
  String get filterArea => 'المساحة';

  @override
  String get filterBedroomsLabel => 'عدد الغرف';

  @override
  String get filterBedroomsAll => 'الكل';

  @override
  String get filterBedrooms5Plus => '+5';

  @override
  String filterShowResults(int count) {
    return 'عرض النتائج ($count)';
  }

  @override
  String get filterReset => 'إعادة تعيين';

  @override
  String get mapEmptyTitle => 'لا توجد عقارات في هذه المنطقة';

  @override
  String get mapEmptyMessage => 'جرّب توسيع نطاق البحث';

  @override
  String get mapViewToggleMap => 'الخريطة';

  @override
  String get mapViewToggleList => 'القائمة';

  @override
  String get mapSearchThisArea => 'البحث في هذه المنطقة';

  @override
  String get mapMarkersTruncated =>
      'تُعرض أقرب 500 نتيجة فقط. صغّر نطاق البحث لرؤية المزيد.';

  @override
  String get listingPropertyInfo => 'معلومات العقار';

  @override
  String get listingNegotiable => 'قابل للتفاوض';

  @override
  String get listingWhatsapp => 'واتساب';

  @override
  String get listingCall => 'اتصال';

  @override
  String get listingReport => 'الإبلاغ عن هذا العقار';

  @override
  String get listingSimilar => 'عقارات مشابهة';

  @override
  String listingMemberSince(String date) {
    return 'عضو منذ $date';
  }

  @override
  String get listingGalleryEmpty => 'لا توجد صور لهذا العقار';

  @override
  String get commonShare => 'مشاركة';

  @override
  String get commonMore => 'المزيد';

  @override
  String get reportSheetTitle => 'الإبلاغ عن هذا العقار';

  @override
  String get reportReasonLabel => 'سبب البلاغ';

  @override
  String get reportReasonInappropriate => 'محتوى غير لائق';

  @override
  String get reportReasonMisleading => 'معلومات غير صحيحة';

  @override
  String get reportReasonDuplicate => 'إعلان مكرر';

  @override
  String get reportReasonFraud => 'عملية احتيال';

  @override
  String get reportReasonOther => 'سبب آخر';

  @override
  String get reportNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get reportSubmit => 'إرسال البلاغ';

  @override
  String get reportSubmitted => 'تم إرسال البلاغ.';

  @override
  String shareCaption(String title, String url) {
    return '$title على الباب العقاري: $url';
  }

  @override
  String contactWhatsappMessage(String title, String price) {
    return 'مرحباً، أنا مهتم بهذا العقار: $title - $price';
  }

  @override
  String get contactLaunchFailed => 'تعذّر فتح التطبيق المطلوب.';

  @override
  String get accountMyListings => 'عقاراتي';

  @override
  String get accountFavorites => 'المفضلة';

  @override
  String get accountMessages => 'الرسائل';

  @override
  String get accountNotifications => 'الإشعارات';

  @override
  String get accountStats => 'إحصائيات مشاهدات عقاراتي';

  @override
  String get accountSettings => 'الإعدادات';

  @override
  String get accountMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String get myListingsStatusAll => 'الكل';

  @override
  String get myListingsStatusPublished => 'منشور';

  @override
  String get myListingsStatusPending => 'قيد المراجعة';

  @override
  String get myListingsStatusRejected => 'مرفوض';

  @override
  String get myListingsStatusSoldRented => 'مباع/مؤجر';

  @override
  String get myListingsActionEdit => 'تعديل';

  @override
  String get myListingsActionPromote => 'تمييز';

  @override
  String get myListingsActionPause => 'تعليق';

  @override
  String get myListingsActionDelete => 'حذف';

  @override
  String get dashKpiTotalUsers => 'إجمالي المستخدمين';

  @override
  String get dashKpiTotalListings => 'إجمالي العقارات';

  @override
  String get dashKpiForSale => 'عقارات للبيع';

  @override
  String get dashKpiForRent => 'عقارات للإيجار';

  @override
  String get dashVisitsLast30Days => 'الزيارات خلال آخر 30 يوم';

  @override
  String get dashListingsByType => 'العقارات حسب النوع';

  @override
  String get dashLatestListings => 'أحدث العقارات المضافة';

  @override
  String get dashMostViewed => 'أكثر العقارات مشاهدة';

  @override
  String dashKpiDelta(int count) {
    return '+$count خلال 30 يوم';
  }

  @override
  String get dashLoginTitle => 'دخول لوحة التحكم';

  @override
  String get dashLoginAdminOnlyError =>
      'هذا الحساب غير مخوّل بالدخول إلى لوحة التحكم.';

  @override
  String get dashModerationQueueTitle => 'طابور المراجعة';

  @override
  String get dashStatusFilterLabel => 'الحالة';

  @override
  String get dashStatusFilterAll => 'كل الحالات';

  @override
  String get dashApprove => 'موافقة';

  @override
  String get dashReject => 'رفض';

  @override
  String get dashRejectReasonLabel => 'سبب الرفض';

  @override
  String get dashRejectReasonRequired => 'أدخل سبب الرفض';

  @override
  String get dashApproved => 'تمت الموافقة على العقار.';

  @override
  String get dashRejected => 'تم رفض العقار.';

  @override
  String get dashColTitle => 'العنوان';

  @override
  String get dashColNeighborhood => 'الحي';

  @override
  String get dashColPrice => 'السعر';

  @override
  String get dashColStatus => 'الحالة';

  @override
  String get dashColDate => 'التاريخ';

  @override
  String get dashColViews => 'المشاهدات';

  @override
  String get dashColActions => 'الإجراءات';

  @override
  String get dashEmptyListingsTitle => 'لا توجد عقارات';

  @override
  String get dashEmptyListingsMessage => 'لا توجد عقارات مطابقة لهذا الفلتر.';

  @override
  String get dashColListing => 'العقار';

  @override
  String get dashColReporter => 'المُبلّغ';

  @override
  String get dashColReason => 'السبب';

  @override
  String get dashColNote => 'الملاحظة';

  @override
  String get dashReportStatusOpen => 'مفتوح';

  @override
  String get dashReportStatusClosed => 'مغلق';

  @override
  String get dashReportClose => 'إغلاق البلاغ';

  @override
  String get dashReportClosed => 'تم إغلاق البلاغ.';

  @override
  String get dashEmptyReportsTitle => 'لا توجد بلاغات';

  @override
  String get dashEmptyReportsMessage => 'لا توجد بلاغات مطابقة لهذا الفلتر.';

  @override
  String get dashExportListingsCsv => 'تصدير العقارات (CSV)';

  @override
  String get dashExportUsersCsv => 'تصدير المستخدمين (CSV)';

  @override
  String get dashExportDone => 'تم تنزيل الملف.';

  @override
  String get dashSettingsNeighborhoods => 'الأحياء';

  @override
  String get dashSettingsQuotas => 'الحصص';

  @override
  String get dashSettingsPages => 'المحتوى الثابت';

  @override
  String get dashColNameAr => 'الاسم (عربي)';

  @override
  String get dashColNameEn => 'الاسم (إنجليزي)';

  @override
  String get dashColSlug => 'المعرف';

  @override
  String get dashColLat => 'خط العرض';

  @override
  String get dashColLng => 'خط الطول';

  @override
  String get dashColActive => 'مفعّل';

  @override
  String get dashActive => 'مفعّل';

  @override
  String get dashInactive => 'غير مفعّل';

  @override
  String get dashAddNeighborhood => 'إضافة حي';

  @override
  String get dashEditNeighborhood => 'تعديل حي';

  @override
  String get dashNeighborhoodSaved => 'تم حفظ الحي.';

  @override
  String get dashNeighborhoodDeleted => 'تم حذف الحي.';

  @override
  String get dashNeighborhoodNameArLabel => 'الاسم (عربي)';

  @override
  String get dashNeighborhoodNameEnLabel => 'الاسم (إنجليزي)';

  @override
  String get dashNeighborhoodSlugLabel => 'المعرف (slug)';

  @override
  String get dashNeighborhoodLatLabel => 'خط العرض (Latitude)';

  @override
  String get dashNeighborhoodLngLabel => 'خط الطول (Longitude)';

  @override
  String get dashNeighborhoodActiveLabel => 'مفعّل';

  @override
  String get dashEmptyNeighborhoodsTitle => 'لا توجد أحياء';

  @override
  String get dashEmptyNeighborhoodsMessage => 'لم يتم إضافة أي حي بعد.';

  @override
  String get dashConfirmDeleteTitle => 'تأكيد الحذف';

  @override
  String get dashConfirmDeleteNeighborhoodMessage =>
      'هل أنت متأكد من حذف هذا الحي؟';

  @override
  String get dashQuotaSeeker => 'الباحث عن عقار';

  @override
  String get dashQuotaOwner => 'مالك عقار';

  @override
  String get dashQuotaAgency => 'مكتب عقاري';

  @override
  String get dashQuotasHint => 'الحد الأقصى لعدد العقارات النشطة لكل دور.';

  @override
  String get dashQuotasSaved => 'تم حفظ الحصص.';

  @override
  String get dashAddPage => 'إضافة صفحة';

  @override
  String get dashEditPage => 'تعديل صفحة';

  @override
  String get dashPageSaved => 'تم حفظ الصفحة.';

  @override
  String get dashPageDeleted => 'تم حذف الصفحة.';

  @override
  String get dashPageSlugLabel => 'المعرف (slug)';

  @override
  String get dashPageTitleArLabel => 'العنوان (عربي)';

  @override
  String get dashPageTitleEnLabel => 'العنوان (إنجليزي)';

  @override
  String get dashPageBodyArLabel => 'المحتوى (عربي)';

  @override
  String get dashPageBodyEnLabel => 'المحتوى (إنجليزي)';

  @override
  String get dashEmptyPagesTitle => 'لا يوجد محتوى';

  @override
  String get dashEmptyPagesMessage => 'لم تتم إضافة أي صفحة بعد.';

  @override
  String get dashPromotionsPackagesTab => 'الباقات';

  @override
  String get dashPromotionsActiveTab => 'الإعلانات';

  @override
  String get dashAddPackage => 'إضافة باقة';

  @override
  String get dashEditPackage => 'تعديل باقة';

  @override
  String get dashPackageSaved => 'تم حفظ الباقة.';

  @override
  String get dashPackageDeleted => 'تم حذف الباقة.';

  @override
  String get dashPackageNameArLabel => 'الاسم (عربي)';

  @override
  String get dashPackageNameEnLabel => 'الاسم (إنجليزي)';

  @override
  String get dashPackageDaysLabel => 'عدد الأيام';

  @override
  String get dashPackagePriceLabel => 'السعر (USD)';

  @override
  String get dashPackageActiveLabel => 'مفعّلة';

  @override
  String get dashColDays => 'عدد الأيام';

  @override
  String get dashEmptyPackagesTitle => 'لا توجد باقات';

  @override
  String get dashEmptyPackagesMessage => 'لم تتم إضافة أي باقة بعد.';

  @override
  String get dashConfirmDeletePackageMessage =>
      'هل أنت متأكد من حذف هذه الباقة؟';

  @override
  String get dashAddPromotion => 'إنشاء إعلان';

  @override
  String get dashPromotionListingIdLabel => 'رقم العقار';

  @override
  String get dashPromotionPackageLabel => 'الباقة';

  @override
  String get dashPromotionCreated => 'تم إنشاء الإعلان.';

  @override
  String get dashColOwner => 'المالك';

  @override
  String get dashColPackage => 'الباقة';

  @override
  String get dashColDaysRemaining => 'الأيام المتبقية';

  @override
  String get dashStatusPending => 'قيد الانتظار';

  @override
  String get dashPromotionStatusActive => 'نشط';

  @override
  String get dashPromotionStatusExpired => 'منتهي';

  @override
  String get dashEmptyPromotionsTitle => 'لا توجد إعلانات';

  @override
  String get dashEmptyPromotionsMessage =>
      'لا توجد إعلانات مطابقة لهذا الفلتر.';

  @override
  String get dashRecordPayment => 'تسجيل دفعة';

  @override
  String get dashTransactionPromotionLabel => 'الإعلان المعلّق';

  @override
  String get dashTransactionAmountLabel => 'المبلغ';

  @override
  String get dashTransactionMethodLabel => 'طريقة الدفع';

  @override
  String get dashTransactionMethodCash => 'نقداً';

  @override
  String get dashTransactionMethodManual => 'يدوي';

  @override
  String get dashTransactionCurrencyLabel => 'العملة';

  @override
  String get dashTransactionReferenceLabel => 'رقم مرجعي (اختياري)';

  @override
  String get dashTransactionRecorded => 'تم تسجيل الدفعة.';

  @override
  String get dashTransactionStatusCompleted => 'مكتمل';

  @override
  String get dashColMethod => 'طريقة الدفع';

  @override
  String get dashColAmount => 'المبلغ';

  @override
  String get dashColReference => 'المرجع';

  @override
  String get dashFilterDateFrom => 'من تاريخ';

  @override
  String get dashFilterDateTo => 'إلى تاريخ';

  @override
  String get dashEmptyTransactionsTitle => 'لا توجد معاملات';

  @override
  String get dashEmptyTransactionsMessage =>
      'لا توجد معاملات مطابقة لهذا الفلتر.';

  @override
  String get dashNoPendingPromotions => 'لا توجد إعلانات معلّقة لتحصيلها.';

  @override
  String get dashNotificationTitleLabel => 'العنوان';

  @override
  String get dashNotificationBodyLabel => 'النص';

  @override
  String get dashNotificationTargetLabel => 'الإرسال إلى';

  @override
  String get dashNotificationTargetAll => 'كل المستخدمين';

  @override
  String get dashNotificationTargetRole => 'حسب الدور';

  @override
  String get dashNotificationTargetUser => 'مستخدم واحد';

  @override
  String get dashNotificationRoleLabel => 'الدور';

  @override
  String get dashNotificationUserLabel => 'المستخدم';

  @override
  String get dashSendBroadcast => 'إرسال';

  @override
  String dashBroadcastSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مستخدم',
      few: 'مستخدمين',
      two: 'مستخدمين',
      one: 'مستخدم',
    );
    return 'تم الإرسال إلى $count $_temp0.';
  }

  @override
  String get dashNotificationPreviewLabel => 'معاينة';

  @override
  String get dashNotificationPreviewEmptyTitle => 'عنوان الإشعار';

  @override
  String get dashNotificationPreviewEmptyBody => 'سيظهر نص الإشعار هنا.';

  @override
  String get dashSidebarCollapse => 'طي القائمة';

  @override
  String get dash404Title => 'الصفحة غير موجودة';

  @override
  String get dash404Message => 'الرابط الذي حاولت الوصول إليه غير موجود.';

  @override
  String get dash404GoHome => 'العودة للرئيسية';

  @override
  String get dashSearchPlaceholder => 'بحث...';

  @override
  String get dashRoleFilterLabel => 'الدور';

  @override
  String get dashRoleFilterAll => 'كل الأدوار';

  @override
  String get dashColPhone => 'الهاتف';

  @override
  String get dashColRole => 'الدور';

  @override
  String get dashUserStatusActive => 'نشط';

  @override
  String get dashUserStatusBlocked => 'محظور';

  @override
  String get dashUserDetailsTitle => 'بيانات المستخدم';

  @override
  String get dashUserBlock => 'حظر';

  @override
  String get dashUserUnblock => 'إلغاء الحظر';

  @override
  String get dashUserBlockReasonLabel => 'سبب الحظر';

  @override
  String get dashUserBlockReasonRequired => 'أدخل سبب الحظر';

  @override
  String get dashUserBlocked => 'تم حظر المستخدم.';

  @override
  String get dashUserUnblocked => 'تم إلغاء حظر المستخدم.';

  @override
  String get dashChangeRoleLabel => 'تغيير الدور';

  @override
  String get dashUserRoleChanged => 'تم تحديث الدور.';

  @override
  String get dashUserListingsTitle => 'العقارات';

  @override
  String dashUserBlockedReason(String reason) {
    return 'محظور — $reason';
  }

  @override
  String get dashEmptyUsersTitle => 'لا يوجد مستخدمون';

  @override
  String get dashEmptyUsersMessage => 'لا يوجد مستخدمون مطابقون لهذا الفلتر.';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get emptyStateDefaultTitle => 'لا يوجد شيء هنا بعد';

  @override
  String get errorStateDefaultTitle => 'حدث خطأ ما';

  @override
  String get errorNetwork => 'تعذّر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.';

  @override
  String get errorTimeout => 'انتهت مهلة الاتصال بالخادم.';

  @override
  String get errorUnauthorized => 'يجب تسجيل الدخول لإتمام هذا الإجراء.';

  @override
  String get errorUnknown => 'حدث خطأ غير متوقع.';

  @override
  String get statsAreaLabel => 'المساحة';

  @override
  String get statsBedroomsLabel => 'غرف النوم';

  @override
  String get statsBathroomsLabel => 'الحمامات';

  @override
  String areaUnit(String value) {
    return '$value م²';
  }

  @override
  String get relativeTimeJustNow => 'الآن';

  @override
  String relativeTimeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'دقيقة',
      few: 'دقائق',
      two: 'دقيقتين',
      one: 'دقيقة',
    );
    return 'منذ $count $_temp0';
  }

  @override
  String relativeTimeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ساعة',
      few: 'ساعات',
      two: 'ساعتين',
      one: 'ساعة',
    );
    return 'منذ $count $_temp0';
  }

  @override
  String relativeTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يوم',
      few: 'أيام',
      two: 'يومين',
      one: 'يوم',
    );
    return 'منذ $count $_temp0';
  }

  @override
  String relativeTimeWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أسبوع',
      few: 'أسابيع',
      two: 'أسبوعين',
      one: 'أسبوع',
    );
    return 'منذ $count $_temp0';
  }

  @override
  String relativeTimeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'شهر',
      few: 'أشهر',
      two: 'شهرين',
      one: 'شهر',
    );
    return 'منذ $count $_temp0';
  }

  @override
  String relativeTimeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سنة',
      few: 'سنوات',
      two: 'سنتين',
      one: 'سنة',
    );
    return 'منذ $count $_temp0';
  }

  @override
  String get accountGuestPromptTitle => 'سجّل الدخول للوصول إلى حسابك';

  @override
  String get accountGuestPromptMessage =>
      'المفضلة والرسائل والإشعارات وإضافة العقارات تحتاج إلى حساب.';

  @override
  String get myListingsEmptyTitle => 'لا توجد عقارات بعد';

  @override
  String get myListingsEmptyMessage =>
      'عقاراتك المنشورة وقيد المراجعة تظهر هنا.';

  @override
  String get myListingsDeleteConfirmTitle => 'حذف العقار؟';

  @override
  String get myListingsDeleteConfirmMessage =>
      'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get myListingsActionRepublish => 'إعادة النشر';

  @override
  String get myListingsRejectionReasonLabel => 'سبب الرفض';

  @override
  String myListingsViewsCount(int count) {
    return '$count مشاهدة';
  }

  @override
  String get myListingsDeleted => 'تم حذف العقار';

  @override
  String get myListingsStatusUpdated => 'تم تحديث حالة العقار';

  @override
  String get statsLast30Days => 'آخر 30 يوماً';

  @override
  String get statsTotalViews => 'إجمالي المشاهدات';

  @override
  String get statsTotalContacts => 'إجمالي التواصل';

  @override
  String get statsByChannelTitle => 'التواصل حسب القناة';

  @override
  String get statsChannelMessage => 'رسالة';

  @override
  String get statsPerListingTitle => 'أداء كل عقار';

  @override
  String get statsEmptyMessage => 'لا توجد بيانات مشاهدات بعد.';

  @override
  String get favoritesEmptyTitle => 'لا توجد عقارات في المفضلة';

  @override
  String get favoritesEmptyMessage =>
      'اضغط على أيقونة القلب في أي عقار لإضافته هنا.';

  @override
  String get favoritesRemoved => 'تمت الإزالة من المفضلة';

  @override
  String get favoriteAdd => 'إضافة إلى المفضلة';

  @override
  String get favoriteRemove => 'إزالة من المفضلة';

  @override
  String get messagesEmptyTitle => 'لا توجد رسائل بعد';

  @override
  String get messagesEmptyMessage => 'تواصل مع مالك عقار لبدء محادثة.';

  @override
  String get messageInputHint => 'اكتب رسالة...';

  @override
  String get messageSendFailed => 'تعذّر إرسال الرسالة';

  @override
  String get messagesConversationEmpty => 'ابدأ المحادثة برسالة.';

  @override
  String get notificationsEmptyTitle => 'لا توجد إشعارات';

  @override
  String get notificationsEmptyMessage =>
      'ستظهر التحديثات المتعلقة بعقاراتك ورسائلك هنا.';

  @override
  String get notificationsSectionToday => 'اليوم';

  @override
  String get notificationsSectionYesterday => 'أمس';

  @override
  String get notificationsSectionEarlier => 'سابقاً';

  @override
  String get settingsLanguageTitle => 'اللغة';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsNotificationsTitle => 'الإشعارات';

  @override
  String get settingsPushToggleLabel => 'الإشعارات الفورية';

  @override
  String get settingsEditProfile => 'تعديل الملف الشخصي';

  @override
  String get settingsChangeAvatar => 'تغيير الصورة الشخصية';

  @override
  String get settingsChangePassword => 'تغيير كلمة المرور';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String get settingsAboutBody =>
      'الباب العقاري — منصة عقارية لمدينة الباب، سوريا.';

  @override
  String get settingsContactSupport => 'تواصل مع الدعم';

  @override
  String get settingsContactSupportMessage =>
      'لأي استفسار، تواصل معنا عبر واتساب.';

  @override
  String get settingsDeleteAccount => 'حذف الحساب';

  @override
  String get settingsDeleteAccountConfirmTitle => 'حذف الحساب؟';

  @override
  String get settingsDeleteAccountConfirmMessage =>
      'سيتم حذف حسابك وكل بياناتك نهائياً.';

  @override
  String get settingsNotAvailableMessage =>
      'هذه الميزة غير متاحة حالياً — تواصل مع الدعم.';

  @override
  String get settingsVersionLabel => 'الإصدار';

  @override
  String get editProfileWhatsappLabel => 'رقم واتساب (اختياري)';

  @override
  String get editProfileSaved => 'تم حفظ التغييرات';

  @override
  String get editProfileChangePhoto => 'تغيير الصورة';

  @override
  String get commonSend => 'إرسال';
}

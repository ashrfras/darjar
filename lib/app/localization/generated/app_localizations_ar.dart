// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'دارجار';

  @override
  String get brandLatin => 'DarJar';

  @override
  String get community => 'المجتمع';

  @override
  String get directory => 'الدليل';

  @override
  String get demoResidence => 'إقامة الياسمين';

  @override
  String get selectResidence => 'اختيار الإقامة';

  @override
  String get residenceSwitcherDescription =>
      'اختر الإقامة التي تريد تصفحها وإدارتها الآن.';

  @override
  String get currentResidence => 'الحالية';

  @override
  String get acceptInvitation => 'انضمام';

  @override
  String get residenceInvitations => 'دعوات الإقامة الجديدة';

  @override
  String get residenceContextLoadError => 'تعذر تحميل إقامات الحساب.';

  @override
  String residenceDisplayName(String name) {
    return 'إقامة $name';
  }

  @override
  String get communityDescription =>
      'مساحة أخبار الجيران والإعلانات والنقاشات داخل الإقامة.';

  @override
  String get shellPreviewDescription =>
      'معاينة هيكل التنقل المتجاوب. ستُضاف وظائف المنتج في المرحلة الثانية.';

  @override
  String get milestoneTwo => 'قريباً في المرحلة الثانية';

  @override
  String get componentGallery => 'معرض المكوّنات';

  @override
  String get componentGalleryDescription =>
      'مرجع داخلي لعناصر واجهة دارجار وحالاتها الأساسية.';

  @override
  String get buttons => 'الأزرار';

  @override
  String get primaryAction => 'إجراء أساسي';

  @override
  String get secondaryAction => 'إجراء ثانوي';

  @override
  String get disabledAction => 'غير متاح';

  @override
  String get fields => 'الحقول';

  @override
  String get residenceName => 'اسم الإقامة';

  @override
  String get residenceNameHint => 'مثال: النخيل';

  @override
  String get residenceNameGuidance =>
      'أدخل اسم الإقامة مباشرة دون «إقامة» أو «Résidence».';

  @override
  String get chipsAndBadges => 'الشرائح والشارات';

  @override
  String get all => 'الكل';

  @override
  String get announcements => 'الإعلانات';

  @override
  String get newLabel => 'جديد';

  @override
  String get completedLabel => 'مكتمل';

  @override
  String get processingLabel => 'قيد المعالجة';

  @override
  String get cards => 'البطاقات';

  @override
  String get sampleCardTitle => 'إعلان من الإقامة';

  @override
  String get sampleCardDescription =>
      'نموذج لبطاقة محتوى بسيطة وواضحة داخل دارجار.';

  @override
  String get onboardingHeadline => 'كل ما يخص إقامتك، في مكان واحد.';

  @override
  String get onboardingDescription =>
      'تابع أخبار إقامتك، واكتشف الخدمات المحلية، واطّلع على الشؤون المالية بكل وضوح وشفافية.';

  @override
  String get getStarted => 'ابدأ الآن';

  @override
  String get back => 'رجوع';

  @override
  String get residenceSetupTitle => 'كيف تريد أن تبدأ؟';

  @override
  String get residenceSetupDescription =>
      'انضم إلى إقامتك الحالية أو أنشئ إقامة جديدة لجيرانك.';

  @override
  String get joinMyResidence => 'الانضمام إلى إقامتي';

  @override
  String get joinMyResidenceDescription =>
      'ابحث عن إقامتك باستعمال الرمز الذي حصلت عليه.';

  @override
  String get createNewResidence => 'إنشاء إقامة جديدة';

  @override
  String get createNewResidenceDescription =>
      'أضف إقامتك وابدأ دعوة جيرانك إليها.';

  @override
  String get createResidenceFormDescription =>
      'أدخل معلومات الإقامة ومعلوماتك الأساسية للمتابعة.';

  @override
  String get yourInformation => 'معلوماتك';

  @override
  String get createResidence => 'إنشاء إقامة';

  @override
  String get joinResidence => 'الانضمام إلى إقامة';

  @override
  String get city => 'المدينة';

  @override
  String get cityHint => 'مثال: الدار البيضاء';

  @override
  String get citySelectHint => 'اختر المدينة';

  @override
  String get cityCasablanca => 'الدار البيضاء';

  @override
  String get cityRabat => 'الرباط';

  @override
  String get cityMarrakesh => 'مراكش';

  @override
  String get cityTangier => 'طنجة';

  @override
  String get cityAgadir => 'أكادير';

  @override
  String get cityFes => 'فاس';

  @override
  String get unit => 'السكن';

  @override
  String get unitHint => 'مثال: العمارة B، الشقة 12';

  @override
  String get invitationCode => 'رمز الدعوة';

  @override
  String get invitationCodeHint => 'مثال: 48273165';

  @override
  String get createAndContinue => 'إنشاء الإقامة والمتابعة';

  @override
  String get joinAndContinue => 'الانضمام والمتابعة';

  @override
  String get residenceAddressHint => 'مثال: 12 شارع الياسمين، حي المعاريف';

  @override
  String get countryCode => 'رمز الدولة';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get phoneNumberHint => 'مثال: 06 12 34 56 78';

  @override
  String get localPhoneNumberHint => 'مثال: 6 12 34 56 78';

  @override
  String get firstName => 'الاسم';

  @override
  String get firstNameHint => 'أدخل اسمك';

  @override
  String get lastName => 'النسب';

  @override
  String get lastNameHint => 'أدخل نسبك';

  @override
  String get lastNamePrivacyHint => 'لا يتم إظهار النسب للسكان الآخرين.';

  @override
  String get joinPhoneDescription =>
      'أدخل رقم هاتفك للتحقق مما إذا كان مرتبطاً بإقامة.';

  @override
  String get verificationCodeNotice => 'سيتم إرسال رمز تحقق إلى رقم هاتفك.';

  @override
  String get verificationCode => 'رمز التحقق';

  @override
  String get verificationCodeHint => 'أدخل أي رمز للاختبار حالياً';

  @override
  String get verify => 'تحقّق';

  @override
  String get phoneNotRegisteredTitle => 'هذا الرقم غير مسجل في أي إقامة';

  @override
  String get phoneNotRegisteredDescription =>
      'إذا كنت قد حصلت على رابط دعوة، فيرجى الضغط عليه للانضمام إلى الإقامة.';

  @override
  String get joinCodeDescription =>
      'أدخل رمز الإقامة لعرض معلوماتها والانضمام إليها مباشرة.';

  @override
  String get searchResidence => 'البحث عن الإقامة';

  @override
  String get searchingResidence => 'جارٍ البحث…';

  @override
  String get residenceCodeInvalid => 'أدخل رمز الإقامة المكوّن من 8 أرقام.';

  @override
  String get residenceCodeNotFound => 'لم نعثر على إقامة بهذا الرمز';

  @override
  String get residenceCodeNotFoundDescription =>
      'تحقّق من الرمز مع الشخص الذي أرسله إليك ثم حاول مجدداً.';

  @override
  String get joinRequestsClosed =>
      'طلبات الانضمام متوقفة حالياً في هذه الإقامة.';

  @override
  String get sendingJoinRequest => 'جارٍ الانضمام…';

  @override
  String get joinRequestSent => 'تم الانضمام إلى الإقامة';

  @override
  String get joinRequestSentDescription =>
      'أصبحت عضويتك فعّالة ويمكنك الآن الدخول إلى محتوى الإقامة.';

  @override
  String get creatingResidence => 'جارٍ إنشاء الإقامة…';

  @override
  String get setupFieldRequired => 'هذا الحقل مطلوب.';

  @override
  String get setupCompleteRequiredFields =>
      'أكمل جميع معلومات الإقامة والاسم والنسب.';

  @override
  String get setupUnexpectedError => 'تعذر إكمال العملية الآن. حاول مجدداً.';

  @override
  String get communityFeedDescription => 'آخر أخبار وإعلانات إقامة الياسمين.';

  @override
  String get newPost => 'منشور جديد';

  @override
  String get officialAnnouncement => 'إعلان رسمي';

  @override
  String get createPost => 'إنشاء منشور';

  @override
  String get createPostDescription =>
      'شارك سؤالاً أو خبراً مع جيرانك داخل الإقامة.';

  @override
  String get postTitle => 'عنوان المنشور';

  @override
  String get postTitleHint => 'اكتب عنواناً واضحاً';

  @override
  String get postBody => 'التفاصيل';

  @override
  String get postBodyHint => 'ماذا تريد أن تشارك مع جيرانك؟';

  @override
  String get publish => 'نشر';

  @override
  String get cancel => 'إلغاء';

  @override
  String get directoryPageDescription =>
      'دليلك المحلي الموثوق لخدمات ومرافق أوصى بها جيرانك.';

  @override
  String get directorySearchHint => 'ابحث عن خدمة أو مكان...';

  @override
  String get nearby => 'قريب';

  @override
  String get craftspeople => 'حرفيون';

  @override
  String get restaurants => 'مطاعم';

  @override
  String get cafes => 'مقاهي';

  @override
  String get pharmacies => 'صيدليات';

  @override
  String get nearbyFacilities => 'مرافق';

  @override
  String get recommendedByNeighbors => 'موصى بها من جيرانك';

  @override
  String get topRatedCraftspeople => 'الحرفيون الأعلى توصية';

  @override
  String get exploreNearby => 'اكتشف ما حولك';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get recommended => 'موصى به';

  @override
  String get recommendedFromResidence => 'موصى به من سكان إقامة الياسمين';

  @override
  String get searchResults => 'نتائج البحث';

  @override
  String get noDirectoryResults =>
      'لم نجد نتائج مطابقة. جرّب كلمة أو فئة أخرى.';

  @override
  String localRecommendations(int count) {
    return '$count توصية من جيرانك';
  }

  @override
  String get directoryProfileNotFound => 'لم يتم العثور على الملف.';

  @override
  String get recommendationScore => 'نقطة الثقة';

  @override
  String get recommendations => 'التوصيات';

  @override
  String get fromYourResidence => 'من إقامتك';

  @override
  String get call => 'اتصال';

  @override
  String get recommend => 'أوصي به';

  @override
  String get workedInResidences => 'إقامات عمل فيها سابقاً';

  @override
  String get recentReviews => 'آراء حديثة';

  @override
  String get noReviewsYet => 'لا توجد آراء مكتوبة بعد.';

  @override
  String get cityProfileTrustNotice =>
      'هذا ملف موحّد على مستوى المدينة. نُبرز لك توصيات سكان إقامتك مع إبقاء الخبرات الموثّقة من الإقامات الأخرى.';

  @override
  String recommendEntry(String name) {
    return 'أوصِ بـ $name';
  }

  @override
  String get recommendationPrompt =>
      'شارك تجربتك لمساعدة جيرانك على اتخاذ قرار موثوق.';

  @override
  String get recommendationHint => 'ماذا أعجبك في الخدمة؟';

  @override
  String get publishRecommendation => 'نشر التوصية';

  @override
  String get recommendationPublished => 'شكراً، نُشرت توصيتك لجيرانك.';

  @override
  String get residencePageDescription =>
      'كل ما يتعلق بإدارة وشؤون الإقامة في مكان واحد.';

  @override
  String get myAccount => 'حسابي';

  @override
  String get residenceFinances => 'مالية الإقامة';

  @override
  String get residenceFinancesDescription =>
      'نظرة واضحة على مداخيل الإقامة ومصاريفها وكيفية استخدام الميزانية.';

  @override
  String get totalIncome => 'مداخيل السنة';

  @override
  String get totalExpenses => 'مصاريف السنة';

  @override
  String get currentBalance => 'الرصيد الحالي';

  @override
  String get collectionRate => 'نسبة التحصيل';

  @override
  String get expenseBreakdown => 'توزيع المصاريف';

  @override
  String get recentExpenses => 'أحدث المصاريف';

  @override
  String get viewAllTransactions => 'عرض جميع العمليات';

  @override
  String get financeTransactions => 'سجل العمليات المالية';

  @override
  String get financeTransactionsDescription =>
      'سجل مفصل لمداخيل الإقامة ومصاريفها خلال الفترة المختارة.';

  @override
  String get selectPeriod => 'اختيار الفترة الزمنية';

  @override
  String periodFromTo(String start, String end) {
    return 'من $start إلى $end';
  }

  @override
  String get income => 'مداخيل';

  @override
  String get expense => 'مصاريف';

  @override
  String get periodIncome => 'مداخيل الفترة';

  @override
  String get periodExpenses => 'مصاريف الفترة';

  @override
  String get noTransactionsInPeriod => 'لا توجد عمليات خلال الفترة المختارة.';

  @override
  String get viewFinanceDetails => 'عرض تفاصيل مالية الإقامة';

  @override
  String get currency => 'درهم';

  @override
  String get supportingDocument => 'المرفق';

  @override
  String get noSupportingDocument => 'لا توجد وثيقة مرفقة';

  @override
  String get attachSupportingDocument => 'إرفاق مستند (اختياري)';

  @override
  String get attachmentHint =>
      'أرفق فاتورة أو إيصالًا أو أي مستند يدعم هذه المعاملة.';

  @override
  String get replaceAttachment => 'استبدال المرفق';

  @override
  String get attachmentInvalid =>
      'تعذر إرفاق الملف. اختر PDF أو صورة بحجم لا يتجاوز 15 MB.';

  @override
  String get viewAttachment => 'عرض المرفق';

  @override
  String get expenseCategoryMaintenance => 'الصيانة والإصلاحات';

  @override
  String get expenseCategoryUtilities => 'الماء والكهرباء';

  @override
  String get expenseCategoryCleaning => 'النظافة';

  @override
  String get expenseCategorySecurity => 'الحراسة';

  @override
  String get expenseCategoryCustom => 'مصروف مخصص';

  @override
  String get financeManagement => 'إدارة مالية الإقامة';

  @override
  String get financeManagementDescription =>
      'سجّل المداخيل الأخرى والمصاريف، وراجع مداخيل الاشتراكات المضافة تلقائياً.';

  @override
  String get manageFinanceDescription =>
      'تسجيل مداخيل الإقامة ومصاريفها وتتبع رصيدها.';

  @override
  String get addFinancialTransaction => 'إضافة عملية';

  @override
  String get addIncome => 'إضافة مدخول آخر';

  @override
  String get addExpense => 'إضافة مصروف';

  @override
  String get transactionType => 'نوع العملية';

  @override
  String get transactionName => 'اسم العملية';

  @override
  String get transactionAmount => 'المبلغ';

  @override
  String get transactionDate => 'تاريخ العملية';

  @override
  String get transactionNote => 'ملاحظة اختيارية';

  @override
  String get expenseCategory => 'نوع المصروف';

  @override
  String get saveTransaction => 'حفظ العملية';

  @override
  String get financeTransactionSaved => 'تم تسجيل العملية المالية.';

  @override
  String get financeTransactionUpdated => 'تم تحديث العملية المالية.';

  @override
  String get financeTransactionDeleted => 'تم حذف العملية المالية.';

  @override
  String get financeInvalidData =>
      'أدخل اسماً ومبلغاً صحيحاً واختر نوع المصروف عند الحاجة.';

  @override
  String get financeLoadError =>
      'تعذر تحميل بيانات مالية الإقامة. حاول مجدداً.';

  @override
  String get noFinancialTransactions => 'لا توجد عمليات مالية مسجلة.';

  @override
  String get noExpensesRecorded => 'لا توجد مصاريف مسجلة خلال هذه السنة.';

  @override
  String get manualTransaction => 'عملية يدوية';

  @override
  String get duesIncome => 'مدخول اشتراك';

  @override
  String duesIncomeForApartment(String apartment, String period) {
    return 'اشتراك الشقة $apartment عن $period';
  }

  @override
  String duesIncomeForApartmentRange(
    String apartment,
    String start,
    String end,
  ) {
    return 'اشتراك الشقة $apartment عن $start إلى $end';
  }

  @override
  String get editFinancialTransaction => 'تعديل العملية المالية';

  @override
  String get deleteFinancialTransaction => 'حذف العملية المالية';

  @override
  String confirmDeleteFinancialTransaction(String name) {
    return 'هل تريد حذف عملية «$name»؟ لا يمكن التراجع عن ذلك.';
  }

  @override
  String get financeTrackingNotice =>
      'دارجار يتتبع الأموال فقط ولا يستلمها أو يعالج أي دفعات.';

  @override
  String get financeAutomaticDuesNotice =>
      'تُضاف أداءات الاشتراكات تلقائياً من إدارة الاشتراكات ولا يمكن تعديلها هنا.';

  @override
  String get duesStatus => 'حالة الواجبات';

  @override
  String get duesDescription => 'راجع السجلات المحدثة يدوياً.';

  @override
  String get managementInformation => 'معلومات الإدارة';

  @override
  String get managementSettingsDescription =>
      'بيانات جهة الإدارة والتواصل والحساب البنكي.';

  @override
  String get managementDescription => 'بيانات التواصل والتحويل البنكي.';

  @override
  String get documents => 'الوثائق';

  @override
  String get documentsDescription =>
      'الوثائق الإدارية ومرفقات المعاملات المالية.';

  @override
  String get documentsPageDescription =>
      'الوثائق الإدارية ومرفقات المعاملات المالية الخاصة بالإقامة.';

  @override
  String get administrativeDocuments => 'الوثائق الإدارية';

  @override
  String get administrativeDocumentsDescription =>
      'الوثائق الرسمية التي ترفعها إدارة الإقامة.';

  @override
  String get attachedDocuments => 'الوثائق المرفقة';

  @override
  String get attachedDocumentsDescription =>
      'الفواتير والإيصالات والمستندات المرفقة بالمعاملات المالية.';

  @override
  String get noAttachedDocuments => 'لا توجد مرفقات للمعاملات المالية بعد.';

  @override
  String get viewAllDocuments => 'عرض كل الوثائق';

  @override
  String get noDocuments => 'لم تتم إضافة أي وثيقة إلى الإقامة بعد.';

  @override
  String get documentsLoadError => 'تعذر تحميل الوثائق. حاول مجدداً.';

  @override
  String get pdfDocument => 'PDF';

  @override
  String get imageDocument => 'صورة';

  @override
  String get documentOpenError => 'تعذر فتح هذه الوثيقة.';

  @override
  String get shareDocument => 'مشاركة الوثيقة';

  @override
  String get documentsManagement => 'إدارة الوثائق';

  @override
  String get documentsManagementDescription =>
      'رفع الوثائق الرسمية وتعديل عناوينها أو حذفها.';

  @override
  String get documentsUploadNotice =>
      'تظهر الوثائق لجميع السكان النشطين في هذه الإقامة. الأنواع المقبولة هي PDF وJPEG وPNG وWebP بحجم أقصى 15 MB.';

  @override
  String get documentsPermissionDenied =>
      'لا تملك صلاحية إدارة وثائق هذه الإقامة.';

  @override
  String get uploadDocument => 'رفع وثيقة';

  @override
  String get documentUploading => 'جارٍ رفع الوثيقة…';

  @override
  String documentUploadInProgress(String title) {
    return 'جارٍ رفع «$title»';
  }

  @override
  String documentUploadProgress(int percentage) {
    return 'اكتمل $percentage% من الرفع';
  }

  @override
  String get documentTitle => 'عنوان الوثيقة';

  @override
  String get selectDocumentFile => 'اختيار صورة أو ملف PDF';

  @override
  String get documentFormRequired => 'أدخل عنوان الوثيقة واختر ملفاً.';

  @override
  String get documentTooLarge => 'يجب ألا يتجاوز حجم الوثيقة 15 MB.';

  @override
  String get documentUnsupportedType =>
      'النوع غير مدعوم. اختر PDF أو JPEG أو PNG أو WebP.';

  @override
  String get documentUploaded => 'تم رفع الوثيقة بنجاح.';

  @override
  String get documentUploadError => 'تعذر رفع الوثيقة. حاول مجدداً.';

  @override
  String get editDocument => 'تعديل الوثيقة';

  @override
  String get documentUpdated => 'تم تحديث عنوان الوثيقة.';

  @override
  String get documentUpdateError => 'تعذر تحديث الوثيقة.';

  @override
  String get deleteDocument => 'حذف الوثيقة';

  @override
  String confirmDeleteDocument(String title) {
    return 'هل تريد حذف وثيقة «$title»؟ لا يمكن التراجع عن ذلك.';
  }

  @override
  String get documentDeleted => 'تم حذف الوثيقة.';

  @override
  String get documentDeleteError => 'تعذر حذف الوثيقة.';

  @override
  String get duesPageDescription =>
      'عرض مبسط لحالة واجبات السكن المسجلة من الإدارة.';

  @override
  String get manualDuesNotice =>
      'دارجار لا يستلم الأموال. يتم الأداء خارج التطبيق وتحدّث الإدارة الحالة يدوياً.';

  @override
  String get duesManagement => 'إدارة الاشتراكات';

  @override
  String get duesManagementDescription =>
      'أنشئ واجبات الشهر تلقائياً لكل شقة وسجّل الأداءات اليدوية.';

  @override
  String get duesCurrentMonth => 'اشتراكات الشهر الحالي';

  @override
  String get duesGeneratedNotice =>
      'تُنشأ الأشهر الناقصة تلقائياً حسب قيمة الاشتراك الحالية، وتُحفظ الأشهر المدفوعة مسبقاً بالقيمة نفسها.';

  @override
  String get duesApartmentsSummary => 'ملخص اشتراكات الشقق';

  @override
  String duesOutstandingPeriods(int count) {
    return 'الأشهر غير المؤداة: $count';
  }

  @override
  String get duesAllPeriodsPaid => 'جميع الأشهر مؤداة';

  @override
  String duesPeriodDetailsFor(String number) {
    return 'تفاصيل اشتراكات الشقة رقم $number';
  }

  @override
  String get duesSelectApartment => 'اختر الشقة';

  @override
  String get duesSelectApartmentError => 'اختر الشقة أولاً.';

  @override
  String get duesPaymentDistribution =>
      'سيُوزع المبلغ تلقائياً على أقدم الأشهر غير المؤداة أولاً.';

  @override
  String duesAdvancePaymentHint(String amount) {
    return 'بعد أداء جميع المستحقات، يمكن دفع أشهر لاحقة كاملة بقيمة $amount درهم للشهر.';
  }

  @override
  String get duesNoApartment =>
      'لم يتم ربط حسابك بشقة بعد. تواصل مع إدارة الإقامة.';

  @override
  String get duesNoRecords => 'لا توجد اشتراكات مسجلة لهذه الشقة بعد.';

  @override
  String get duesNoApartments =>
      'أضف الشقق أولاً حتى يتم إنشاء اشتراكات الشهر.';

  @override
  String duesApartment(String number) {
    return 'الشقة رقم $number';
  }

  @override
  String duesPeriod(String period) {
    return 'اشتراك $period';
  }

  @override
  String get duesExpected => 'المبلغ المنتظر';

  @override
  String get duesCollected => 'المبلغ المحصل';

  @override
  String get duesRemaining => 'المبلغ المتبقي';

  @override
  String get duesDebitBalance => 'الرصيد المدين';

  @override
  String get duesCreditBalance => 'الرصيد الدائن';

  @override
  String get duesPrepaidMonths => 'أشهر مؤداة مسبقاً';

  @override
  String get duesAmountDue => 'المبلغ المستحق';

  @override
  String get duesAmountPaid => 'المبلغ المؤدى';

  @override
  String get duesPaymentHistory => 'سجل الأداءات';

  @override
  String get showMore => 'عرض المزيد';

  @override
  String get duesNoPayments => 'لم يتم تسجيل أي أداء بعد.';

  @override
  String get duesStatusUnpaid => 'غير مؤدى';

  @override
  String get duesStatusPartial => 'مؤدى جزئياً';

  @override
  String get duesStatusPaid => 'مؤدى';

  @override
  String get duesRecordPayment => 'تسجيل أداء';

  @override
  String duesRecordPaymentFor(String number) {
    return 'تسجيل أداء للشقة رقم $number';
  }

  @override
  String get duesPaymentAmount => 'المبلغ المؤدى';

  @override
  String get duesPaymentDate => 'تاريخ الأداء';

  @override
  String get duesPaymentNote => 'ملاحظة اختيارية';

  @override
  String get duesSavePayment => 'حفظ الأداء';

  @override
  String get duesPaymentSaved => 'تم تسجيل الأداء بنجاح.';

  @override
  String get duesInvalidPayment =>
      'أدخل مبلغاً صحيحاً. يجب أن يساوي الجزء المدفوع مسبقاً قيمة شهر كامل أو عدة أشهر.';

  @override
  String get duesLoadError => 'تعذر تحميل بيانات الاشتراكات. حاول مجدداً.';

  @override
  String duesRecordedOn(String date) {
    return 'سُجّل بتاريخ $date';
  }

  @override
  String get managementPageDescription =>
      'معلومات إدارة الإقامة وطرق التواصل المتاحة.';

  @override
  String get residenceBuildingCount => 'عدد العمارات';

  @override
  String get residenceApartmentCount => 'عدد الشقق';

  @override
  String get residenceConstructionYear => 'سنة البناء';

  @override
  String get managementCompany => 'جهة الإدارة';

  @override
  String get phone => 'الهاتف';

  @override
  String get officeHours => 'ساعات العمل';

  @override
  String get bankInformation => 'معلومات التحويل البنكي';

  @override
  String get bank => 'البنك';

  @override
  String get bankName => 'اسم البنك';

  @override
  String get bankAccount => 'رقم الحساب';

  @override
  String get externalTransferNotice =>
      'يتم التحويل خارج دارجار. لا يعالج التطبيق أي دفعات.';

  @override
  String get profile => 'حسابي';

  @override
  String get profileResidences => 'الإقامات';

  @override
  String get profileNoResidences => 'لا توجد إقامات مرتبطة بهذا الحساب.';

  @override
  String profileApartmentNumber(String number) {
    return 'الشقة رقم $number';
  }

  @override
  String get profileApartmentNotAssigned => 'لم تُحدّد الشقة بعد';

  @override
  String get profileNameRequired => 'أدخل الاسم والنسب.';

  @override
  String get profileSaved => 'تم حفظ معلومات الحساب.';

  @override
  String get profileSaving => 'جارٍ الحفظ…';

  @override
  String get edit => 'تعديل';

  @override
  String get editProfileName => 'تعديل الاسم والنسب';

  @override
  String get editProfileNameDescription =>
      'حدّث الاسم الذي يظهر لجيرانك في الإقامات.';

  @override
  String get profileRolePresident => 'رئيس';

  @override
  String get profileRoleDeputy => 'نائب';

  @override
  String get profileRoleTreasurer => 'أمين';

  @override
  String get profileRoleResident => 'ساكن';

  @override
  String get residenceAdministration => 'الإدارة';

  @override
  String get residenceSettings => 'إعدادات الإقامة';

  @override
  String get apartments => 'الشقق والسكان';

  @override
  String get apartmentsManagementDescription =>
      'إدارة الشقق وتوزيع السكان داخل الإقامة';

  @override
  String get projects => 'المشاريع';

  @override
  String get projectsManagementDescription =>
      'المشاريع الاستثنائية، مشاريع الصيانة';

  @override
  String get residenceManagementDescription =>
      'هيكلة الإقامة، معلومات الإقامة، قيمة الاشتراك';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get residence => 'الإقامة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get generalSettings => 'الإعدادات العامة';

  @override
  String get professionalSettings => 'الإعدادات الاحترافية';

  @override
  String get professionalAccountDescription =>
      'من أجل إدارة إقامات متعددة، يرجى التبديل إلى الحساب الاحترافي.';

  @override
  String get switchToProfessionalAccount => 'التبديل إلى الحساب الاحترافي';

  @override
  String get replayOnboarding => 'إعادة عرض البداية';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get markAllNotificationsRead => 'تحديد الكل كمقروء';

  @override
  String get noNotifications => 'لا توجد إشعارات حاليًا.';

  @override
  String get notificationsLoadError => 'تعذّر تحميل الإشعارات.';

  @override
  String get newPostNotificationTitle => 'منشور جديد';

  @override
  String newPostNotificationBody(String author) {
    return 'أضاف $author منشورًا جديدًا.';
  }

  @override
  String get duesOverdueNotificationTitle => 'تأخر الأداء';

  @override
  String duesOverdueNotificationBody(String period) {
    return 'تأخر أداء واجب الفترة $period.';
  }

  @override
  String get budgetChangedNotificationTitle => 'تحديث الميزانية';

  @override
  String get budgetChangedNotificationBody => 'تم تحديث ميزانية الإقامة.';

  @override
  String get waterInterruptionNotificationTitle => 'انقطاع مبرمج للماء';

  @override
  String get waterInterruptionNotificationBody =>
      'سيتم قطع الماء غداً من 6 إلى 10 صباحاً لأشغال الصيانة.';

  @override
  String get duesReminderNotificationTitle => 'تذكير بواجبات الإقامة';

  @override
  String get duesReminderNotificationBody =>
      'يرجى مراجعة حالة واجبات هذا الشهر في صفحة الإقامة.';

  @override
  String get maintenanceNotificationTitle => 'صيانة المصعد';

  @override
  String get maintenanceNotificationBody =>
      'اكتملت صيانة المصعد وأصبح متاحاً للاستعمال.';

  @override
  String get notificationTimeMinutes => 'منذ 15 د';

  @override
  String get notificationTimeHours => 'منذ ساعتين';

  @override
  String get notificationTimeYesterday => 'أمس';

  @override
  String get communityNotifications => 'إشعارات المجتمع';

  @override
  String get residenceNotifications => 'إشعارات الإقامة';

  @override
  String get importantNotifications => 'إشعارات هامة';

  @override
  String duesMarkedPaidNotification(String period) {
    return 'تم تسجيل مستحقات $period كمؤداة';
  }

  @override
  String overdueDuesNotification(String period) {
    return 'مستحقات $period متأخرة';
  }

  @override
  String get membershipApprovedNotification =>
      'وافق الرئيس على طلب انضمامك إلى الإقامة';

  @override
  String get residenceSettingsPageDescription =>
      'تحكّم في معلومات الإقامة وهيكلها والاشتراك.';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get residenceInformation => 'معلومات الإقامة';

  @override
  String get residenceInformationDescription =>
      'البيانات الأساسية التي تظهر لسكان الإقامة.';

  @override
  String get residenceId => 'معرّف الإقامة';

  @override
  String get residenceImage => 'صورة أو شعار الإقامة';

  @override
  String get residenceImageOptional => 'اختياري، ويمكن تغييره في أي وقت.';

  @override
  String get addImage => 'إضافة صورة';

  @override
  String get removeImage => 'إزالة الصورة';

  @override
  String get address => 'العنوان';

  @override
  String get establishmentYear => 'سنة التأسيس';

  @override
  String get residenceStructure => 'هيكل الإقامة';

  @override
  String get residenceStructureDescription =>
      'أنشئ مباني الإقامة وحدد اسماً وعدد الطوابق لكل مبنى.';

  @override
  String get buildings => 'البنايات';

  @override
  String get floors => 'الطوابق';

  @override
  String get manageStructure => 'إدارة الهيكل';

  @override
  String get buildingName => 'اسم المبنى';

  @override
  String get buildingNameHint => 'مثال: جناح أ';

  @override
  String get floorCount => 'عدد الطوابق';

  @override
  String buildingFloorCount(int count) {
    return 'عدد الطوابق: $count';
  }

  @override
  String get addBuilding => 'إضافة مبنى';

  @override
  String get editBuilding => 'تعديل المبنى';

  @override
  String get deleteBuilding => 'حذف المبنى';

  @override
  String get atLeastOneBuilding =>
      'يجب أن تحتوي الإقامة على مبنى واحد على الأقل.';

  @override
  String get checkBuildingFields => 'أدخل اسم المبنى وعدد طوابق صحيحاً.';

  @override
  String get structureContainsApartments =>
      'لا يمكن حذف مبنى أو طابق يحتوي على شقق. احذف الشقق أولاً.';

  @override
  String confirmDeleteBuilding(String name) {
    return 'هل تريد حذف $name من هيكل الإقامة؟';
  }

  @override
  String get delete => 'حذف';

  @override
  String get subscription => 'الاشتراك';

  @override
  String get subscriptionDescription =>
      'حدّد القيمة الافتراضية لاشتراك سكان الإقامة.';

  @override
  String get defaultSubscription => 'الاشتراك الافتراضي';

  @override
  String get monthly => 'شهري';

  @override
  String get amount => 'القيمة';

  @override
  String get joiningResidence => 'الانضمام للإقامة';

  @override
  String get joiningResidenceDescription =>
      'شارك الدعوة وتحكّم في استقبال طلبات السكان الجدد.';

  @override
  String get permanentInvitationLink => 'رابط الدعوة الدائم';

  @override
  String get copyLink => 'نسخ الرابط';

  @override
  String get showQrCode => 'عرض رمز QR';

  @override
  String get hideQrCode => 'إخفاء رمز QR';

  @override
  String get invitationQrCode => 'رمز دعوة الإقامة';

  @override
  String get close => 'إغلاق';

  @override
  String get scanToJoin => 'امسح الرمز للانضمام';

  @override
  String get allowJoinRequests => 'السماح بطلبات انضمام جديدة';

  @override
  String get joinRequestsEnabledDescription =>
      'يمكن للسكان الجدد إرسال طلب للانضمام.';

  @override
  String get joinRequestsDisabledDescription =>
      'طلبات الانضمام الجديدة متوقفة حالياً.';

  @override
  String get invitationExplorationNotice =>
      'يبقى الرابط صالحاً لاستكشاف الإقامة على الويب، لكن لا يمكن إرسال طلب انضمام جديد.';

  @override
  String get invitationLinkCopied => 'تم نسخ رابط الدعوة.';

  @override
  String get residenceSettingsSaved => 'تم حفظ إعدادات الإقامة.';

  @override
  String get unsavedChangesTitle => 'لم يتم حفظ التعديلات';

  @override
  String get unsavedChangesDescription =>
      'لم يتم حفظ التعديلات التي أجريتها. هل تريد حفظها قبل العودة؟';

  @override
  String get discardChanges => 'العودة دون حفظ';

  @override
  String get checkResidenceSettingsFields =>
      'تحقّق من معلومات الإقامة وقيمة الاشتراك.';

  @override
  String get authPhoneTitle => 'سجّل الدخول برقم هاتفك';

  @override
  String get authPhoneDescription =>
      'سنرسل إليك رمزاً قصيراً للتحقق من رقم الهاتف وحماية حسابك.';

  @override
  String get authPhoneHint => '0600000001';

  @override
  String get authSendCode => 'إرسال رمز التحقق';

  @override
  String get authSendingCode => 'جارٍ إرسال الرمز…';

  @override
  String get authCodeTitle => 'أدخل رمز التحقق';

  @override
  String authCodeDescription(String phoneNumber) {
    return 'أدخل الرمز المكوّن من 6 أرقام المرسل إلى $phoneNumber.';
  }

  @override
  String get authCodeHint => '6 أرقام';

  @override
  String get authVerifying => 'جارٍ التحقق…';

  @override
  String get authChangePhone => 'تغيير رقم الهاتف';

  @override
  String get authPrivacyNotice =>
      'يُستخدم رقم هاتفك لتسجيل الدخول وحماية حسابك وفق سياسة الخصوصية.';

  @override
  String get authInvalidPhone => 'أدخل رقم هاتف مغربي صحيحاً.';

  @override
  String get authInvalidCode => 'رمز التحقق غير صحيح. راجع الرمز وحاول مجدداً.';

  @override
  String get authCodeExpired => 'انتهت صلاحية الرمز. اطلب رمزاً جديداً.';

  @override
  String get authTooManyRequests =>
      'تمت محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.';

  @override
  String get authNetworkError => 'تعذر الاتصال. تحقق من الإنترنت وحاول مجدداً.';

  @override
  String get authUnauthorizedDomain =>
      'هذا النطاق غير مسموح له بتسجيل الدخول. أضفه إلى النطاقات المعتمدة في Firebase Authentication.';

  @override
  String get authCaptchaFailed =>
      'تعذر إكمال التحقق الأمني. أعد المحاولة وأكمل اختبار reCAPTCHA.';

  @override
  String get authPhoneOperationNotAllowed =>
      'عملية تسجيل الدخول بالهاتف غير مسموحة. تحقّق من السماح للمغرب في سياسة مناطق SMS وربط المشروع بحساب فوترة.';

  @override
  String get authUnexpectedError => 'تعذر تسجيل الدخول الآن. حاول مجدداً.';

  @override
  String get accountResolutionTitle => 'تأكيد معلوماتك';

  @override
  String get accountResolutionDescription =>
      'تحقّق من معلوماتك، ثم اختر الإقامات التي تنتمي إليها.';

  @override
  String get accountResolutionFullName => 'الاسم الكامل';

  @override
  String get accountResolutionInvitationsTitle => 'تمت دعوتك إلى هذه الإقامات';

  @override
  String get accountResolutionInvitationsDescription =>
      'علّم الإقامات التي تنتمي إليها. ستبقى الدعوات غير المحددة معلّقة لتراجعها لاحقاً.';

  @override
  String accountResolutionRole(String role) {
    return 'الصفة: $role';
  }

  @override
  String get accountRoleResident => 'ساكن';

  @override
  String get accountRoleModerator => 'أمين';

  @override
  String get accountRoleManager => 'نائب';

  @override
  String get accountRoleOwner => 'رئيس';

  @override
  String get accountResolutionConfirm => 'تأكيد والانضمام إلى الإقامات المحددة';

  @override
  String get accountResolutionAccepting => 'جارٍ تأكيد العضوية…';

  @override
  String get accountResolutionPendingNotice =>
      'لن تُرفض الإقامات غير المحددة، وستبقى دعواتها معلّقة.';

  @override
  String get accountResolutionRetry => 'إعادة المحاولة';

  @override
  String get accountResolutionPermissionDenied =>
      'لا تسمح قواعد قاعدة البيانات بقراءة هذه الدعوات أو قبولها. انشر قواعد Firestore الجديدة ثم حاول مجدداً.';

  @override
  String get accountResolutionFailedPrecondition =>
      'فهرس قاعدة البيانات المطلوب غير جاهز بعد. انتظر اكتمال بنائه ثم حاول مجدداً.';

  @override
  String get accountResolutionMissingProfile =>
      'بيانات الاسم أو النسب في الدعوة غير مكتملة.';

  @override
  String get accountResolutionSignedOut =>
      'انتهت جلسة تسجيل الدخول. سجّل الدخول مجدداً.';

  @override
  String get accountResolutionUnexpectedError =>
      'تعذر تحميل الدعوات أو تأكيدها الآن. حاول مجدداً.';
}

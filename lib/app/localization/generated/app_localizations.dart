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
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'دارجار'**
  String get appName;

  /// No description provided for @brandLatin.
  ///
  /// In ar, this message translates to:
  /// **'DarJar'**
  String get brandLatin;

  /// No description provided for @community.
  ///
  /// In ar, this message translates to:
  /// **'المجتمع'**
  String get community;

  /// No description provided for @directory.
  ///
  /// In ar, this message translates to:
  /// **'الدليل'**
  String get directory;

  /// No description provided for @demoResidence.
  ///
  /// In ar, this message translates to:
  /// **'إقامة الياسمين'**
  String get demoResidence;

  /// No description provided for @communityDescription.
  ///
  /// In ar, this message translates to:
  /// **'مساحة أخبار الجيران والإعلانات والنقاشات داخل الإقامة.'**
  String get communityDescription;

  /// No description provided for @shellPreviewDescription.
  ///
  /// In ar, this message translates to:
  /// **'معاينة هيكل التنقل المتجاوب. ستُضاف وظائف المنتج في المرحلة الثانية.'**
  String get shellPreviewDescription;

  /// No description provided for @milestoneTwo.
  ///
  /// In ar, this message translates to:
  /// **'قريباً في المرحلة الثانية'**
  String get milestoneTwo;

  /// No description provided for @componentGallery.
  ///
  /// In ar, this message translates to:
  /// **'معرض المكوّنات'**
  String get componentGallery;

  /// No description provided for @componentGalleryDescription.
  ///
  /// In ar, this message translates to:
  /// **'مرجع داخلي لعناصر واجهة دارجار وحالاتها الأساسية.'**
  String get componentGalleryDescription;

  /// No description provided for @buttons.
  ///
  /// In ar, this message translates to:
  /// **'الأزرار'**
  String get buttons;

  /// No description provided for @primaryAction.
  ///
  /// In ar, this message translates to:
  /// **'إجراء أساسي'**
  String get primaryAction;

  /// No description provided for @secondaryAction.
  ///
  /// In ar, this message translates to:
  /// **'إجراء ثانوي'**
  String get secondaryAction;

  /// No description provided for @disabledAction.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get disabledAction;

  /// No description provided for @fields.
  ///
  /// In ar, this message translates to:
  /// **'الحقول'**
  String get fields;

  /// No description provided for @residenceName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الإقامة'**
  String get residenceName;

  /// No description provided for @residenceNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: إقامة الياسمين'**
  String get residenceNameHint;

  /// No description provided for @chipsAndBadges.
  ///
  /// In ar, this message translates to:
  /// **'الشرائح والشارات'**
  String get chipsAndBadges;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @announcements.
  ///
  /// In ar, this message translates to:
  /// **'الإعلانات'**
  String get announcements;

  /// No description provided for @newLabel.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get newLabel;

  /// No description provided for @completedLabel.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get completedLabel;

  /// No description provided for @processingLabel.
  ///
  /// In ar, this message translates to:
  /// **'قيد المعالجة'**
  String get processingLabel;

  /// No description provided for @cards.
  ///
  /// In ar, this message translates to:
  /// **'البطاقات'**
  String get cards;

  /// No description provided for @sampleCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعلان من الإقامة'**
  String get sampleCardTitle;

  /// No description provided for @sampleCardDescription.
  ///
  /// In ar, this message translates to:
  /// **'نموذج لبطاقة محتوى بسيطة وواضحة داخل دارجار.'**
  String get sampleCardDescription;

  /// No description provided for @onboardingHeadline.
  ///
  /// In ar, this message translates to:
  /// **'كل ما يخص إقامتك، في مكان واحد.'**
  String get onboardingHeadline;

  /// No description provided for @onboardingDescription.
  ///
  /// In ar, this message translates to:
  /// **'تابع أخبار إقامتك، واكتشف الخدمات المحلية، واطّلع على الشؤون المالية بكل وضوح وشفافية.'**
  String get onboardingDescription;

  /// No description provided for @getStarted.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get getStarted;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @residenceSetupTitle.
  ///
  /// In ar, this message translates to:
  /// **'لنربطك بإقامتك'**
  String get residenceSetupTitle;

  /// No description provided for @residenceSetupDescription.
  ///
  /// In ar, this message translates to:
  /// **'يمكن لأي ساكن إنشاء إقامة جديدة أو الانضمام بدعوة من أحد الجيران.'**
  String get residenceSetupDescription;

  /// No description provided for @createResidence.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء إقامة'**
  String get createResidence;

  /// No description provided for @joinResidence.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام إلى إقامة'**
  String get joinResidence;

  /// No description provided for @city.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get city;

  /// No description provided for @cityHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: الدار البيضاء'**
  String get cityHint;

  /// No description provided for @unit.
  ///
  /// In ar, this message translates to:
  /// **'السكن'**
  String get unit;

  /// No description provided for @unitHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: العمارة B، الشقة 12'**
  String get unitHint;

  /// No description provided for @invitationCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز الدعوة'**
  String get invitationCode;

  /// No description provided for @invitationCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز الذي أرسله لك جارك'**
  String get invitationCodeHint;

  /// No description provided for @createAndContinue.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الإقامة والمتابعة'**
  String get createAndContinue;

  /// No description provided for @joinAndContinue.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام والمتابعة'**
  String get joinAndContinue;

  /// No description provided for @communityFeedDescription.
  ///
  /// In ar, this message translates to:
  /// **'آخر أخبار وإعلانات إقامة الياسمين.'**
  String get communityFeedDescription;

  /// No description provided for @newPost.
  ///
  /// In ar, this message translates to:
  /// **'منشور جديد'**
  String get newPost;

  /// No description provided for @officialAnnouncement.
  ///
  /// In ar, this message translates to:
  /// **'إعلان رسمي'**
  String get officialAnnouncement;

  /// No description provided for @createPost.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء منشور'**
  String get createPost;

  /// No description provided for @createPostDescription.
  ///
  /// In ar, this message translates to:
  /// **'شارك سؤالاً أو خبراً مع جيرانك داخل الإقامة.'**
  String get createPostDescription;

  /// No description provided for @postTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان المنشور'**
  String get postTitle;

  /// No description provided for @postTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب عنواناً واضحاً'**
  String get postTitleHint;

  /// No description provided for @postBody.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل'**
  String get postBody;

  /// No description provided for @postBodyHint.
  ///
  /// In ar, this message translates to:
  /// **'ماذا تريد أن تشارك مع جيرانك؟'**
  String get postBodyHint;

  /// No description provided for @publish.
  ///
  /// In ar, this message translates to:
  /// **'نشر'**
  String get publish;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @directoryPageDescription.
  ///
  /// In ar, this message translates to:
  /// **'دليلك المحلي الموثوق لخدمات ومرافق أوصى بها جيرانك.'**
  String get directoryPageDescription;

  /// No description provided for @directorySearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن خدمة أو مكان...'**
  String get directorySearchHint;

  /// No description provided for @nearby.
  ///
  /// In ar, this message translates to:
  /// **'قريب'**
  String get nearby;

  /// No description provided for @craftspeople.
  ///
  /// In ar, this message translates to:
  /// **'حرفيون'**
  String get craftspeople;

  /// No description provided for @restaurants.
  ///
  /// In ar, this message translates to:
  /// **'مطاعم'**
  String get restaurants;

  /// No description provided for @cafes.
  ///
  /// In ar, this message translates to:
  /// **'مقاهي'**
  String get cafes;

  /// No description provided for @pharmacies.
  ///
  /// In ar, this message translates to:
  /// **'صيدليات'**
  String get pharmacies;

  /// No description provided for @nearbyFacilities.
  ///
  /// In ar, this message translates to:
  /// **'مرافق'**
  String get nearbyFacilities;

  /// No description provided for @recommendedByNeighbors.
  ///
  /// In ar, this message translates to:
  /// **'موصى بها من جيرانك'**
  String get recommendedByNeighbors;

  /// No description provided for @topRatedCraftspeople.
  ///
  /// In ar, this message translates to:
  /// **'الحرفيون الأعلى توصية'**
  String get topRatedCraftspeople;

  /// No description provided for @exploreNearby.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف ما حولك'**
  String get exploreNearby;

  /// No description provided for @viewAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get viewAll;

  /// No description provided for @recommended.
  ///
  /// In ar, this message translates to:
  /// **'موصى به'**
  String get recommended;

  /// No description provided for @recommendedFromResidence.
  ///
  /// In ar, this message translates to:
  /// **'موصى به من سكان إقامة الياسمين'**
  String get recommendedFromResidence;

  /// No description provided for @searchResults.
  ///
  /// In ar, this message translates to:
  /// **'نتائج البحث'**
  String get searchResults;

  /// No description provided for @noDirectoryResults.
  ///
  /// In ar, this message translates to:
  /// **'لم نجد نتائج مطابقة. جرّب كلمة أو فئة أخرى.'**
  String get noDirectoryResults;

  /// No description provided for @localRecommendations.
  ///
  /// In ar, this message translates to:
  /// **'{count} توصية من جيرانك'**
  String localRecommendations(int count);

  /// No description provided for @directoryProfileNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على الملف.'**
  String get directoryProfileNotFound;

  /// No description provided for @recommendationScore.
  ///
  /// In ar, this message translates to:
  /// **'نقطة الثقة'**
  String get recommendationScore;

  /// No description provided for @recommendations.
  ///
  /// In ar, this message translates to:
  /// **'التوصيات'**
  String get recommendations;

  /// No description provided for @fromYourResidence.
  ///
  /// In ar, this message translates to:
  /// **'من إقامتك'**
  String get fromYourResidence;

  /// No description provided for @call.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get call;

  /// No description provided for @recommend.
  ///
  /// In ar, this message translates to:
  /// **'أوصي به'**
  String get recommend;

  /// No description provided for @workedInResidences.
  ///
  /// In ar, this message translates to:
  /// **'إقامات عمل فيها سابقاً'**
  String get workedInResidences;

  /// No description provided for @recentReviews.
  ///
  /// In ar, this message translates to:
  /// **'آراء حديثة'**
  String get recentReviews;

  /// No description provided for @noReviewsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد آراء مكتوبة بعد.'**
  String get noReviewsYet;

  /// No description provided for @cityProfileTrustNotice.
  ///
  /// In ar, this message translates to:
  /// **'هذا ملف موحّد على مستوى المدينة. نُبرز لك توصيات سكان إقامتك مع إبقاء الخبرات الموثّقة من الإقامات الأخرى.'**
  String get cityProfileTrustNotice;

  /// No description provided for @recommendEntry.
  ///
  /// In ar, this message translates to:
  /// **'أوصِ بـ {name}'**
  String recommendEntry(String name);

  /// No description provided for @recommendationPrompt.
  ///
  /// In ar, this message translates to:
  /// **'شارك تجربتك لمساعدة جيرانك على اتخاذ قرار موثوق.'**
  String get recommendationPrompt;

  /// No description provided for @recommendationHint.
  ///
  /// In ar, this message translates to:
  /// **'ماذا أعجبك في الخدمة؟'**
  String get recommendationHint;

  /// No description provided for @publishRecommendation.
  ///
  /// In ar, this message translates to:
  /// **'نشر التوصية'**
  String get publishRecommendation;

  /// No description provided for @recommendationPublished.
  ///
  /// In ar, this message translates to:
  /// **'شكراً، نُشرت توصيتك لجيرانك.'**
  String get recommendationPublished;

  /// No description provided for @residencePageDescription.
  ///
  /// In ar, this message translates to:
  /// **'كل ما يتعلق بإدارة وشؤون الإقامة في مكان واحد.'**
  String get residencePageDescription;

  /// No description provided for @myAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get myAccount;

  /// No description provided for @residenceFinances.
  ///
  /// In ar, this message translates to:
  /// **'مالية الإقامة'**
  String get residenceFinances;

  /// No description provided for @residenceFinancesDescription.
  ///
  /// In ar, this message translates to:
  /// **'نظرة واضحة على مداخيل الإقامة ومصاريفها وكيفية استخدام الميزانية.'**
  String get residenceFinancesDescription;

  /// No description provided for @totalIncome.
  ///
  /// In ar, this message translates to:
  /// **'مداخيل السنة'**
  String get totalIncome;

  /// No description provided for @totalExpenses.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف السنة'**
  String get totalExpenses;

  /// No description provided for @currentBalance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد الحالي'**
  String get currentBalance;

  /// No description provided for @collectionRate.
  ///
  /// In ar, this message translates to:
  /// **'نسبة التحصيل'**
  String get collectionRate;

  /// No description provided for @expenseBreakdown.
  ///
  /// In ar, this message translates to:
  /// **'توزيع المصاريف'**
  String get expenseBreakdown;

  /// No description provided for @recentExpenses.
  ///
  /// In ar, this message translates to:
  /// **'أحدث المصاريف'**
  String get recentExpenses;

  /// No description provided for @viewAllTransactions.
  ///
  /// In ar, this message translates to:
  /// **'عرض جميع العمليات'**
  String get viewAllTransactions;

  /// No description provided for @financeTransactions.
  ///
  /// In ar, this message translates to:
  /// **'سجل العمليات المالية'**
  String get financeTransactions;

  /// No description provided for @financeTransactionsDescription.
  ///
  /// In ar, this message translates to:
  /// **'سجل مفصل لمداخيل الإقامة ومصاريفها خلال الفترة المختارة.'**
  String get financeTransactionsDescription;

  /// No description provided for @selectPeriod.
  ///
  /// In ar, this message translates to:
  /// **'اختيار الفترة الزمنية'**
  String get selectPeriod;

  /// No description provided for @periodFromTo.
  ///
  /// In ar, this message translates to:
  /// **'من {start} إلى {end}'**
  String periodFromTo(String start, String end);

  /// No description provided for @income.
  ///
  /// In ar, this message translates to:
  /// **'مداخيل'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف'**
  String get expense;

  /// No description provided for @periodIncome.
  ///
  /// In ar, this message translates to:
  /// **'مداخيل الفترة'**
  String get periodIncome;

  /// No description provided for @periodExpenses.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف الفترة'**
  String get periodExpenses;

  /// No description provided for @noTransactionsInPeriod.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عمليات خلال الفترة المختارة.'**
  String get noTransactionsInPeriod;

  /// No description provided for @viewFinanceDetails.
  ///
  /// In ar, this message translates to:
  /// **'عرض تفاصيل مالية الإقامة'**
  String get viewFinanceDetails;

  /// No description provided for @currency.
  ///
  /// In ar, this message translates to:
  /// **'درهم'**
  String get currency;

  /// No description provided for @supportingDocument.
  ///
  /// In ar, this message translates to:
  /// **'الوثيقة المثبتة'**
  String get supportingDocument;

  /// No description provided for @noSupportingDocument.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد وثيقة مرفقة'**
  String get noSupportingDocument;

  /// No description provided for @expenseCategoryMaintenance.
  ///
  /// In ar, this message translates to:
  /// **'الصيانة والإصلاحات'**
  String get expenseCategoryMaintenance;

  /// No description provided for @expenseCategoryUtilities.
  ///
  /// In ar, this message translates to:
  /// **'الماء والكهرباء'**
  String get expenseCategoryUtilities;

  /// No description provided for @expenseCategoryCleaning.
  ///
  /// In ar, this message translates to:
  /// **'النظافة'**
  String get expenseCategoryCleaning;

  /// No description provided for @expenseCategorySecurity.
  ///
  /// In ar, this message translates to:
  /// **'الحراسة'**
  String get expenseCategorySecurity;

  /// No description provided for @duesStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة الواجبات'**
  String get duesStatus;

  /// No description provided for @duesDescription.
  ///
  /// In ar, this message translates to:
  /// **'راجع السجلات المحدثة يدوياً.'**
  String get duesDescription;

  /// No description provided for @managementInformation.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الإدارة'**
  String get managementInformation;

  /// No description provided for @managementDescription.
  ///
  /// In ar, this message translates to:
  /// **'بيانات التواصل والتحويل البنكي.'**
  String get managementDescription;

  /// No description provided for @documents.
  ///
  /// In ar, this message translates to:
  /// **'الوثائق'**
  String get documents;

  /// No description provided for @documentsDescription.
  ///
  /// In ar, this message translates to:
  /// **'الإعلانات والوثائق الرسمية قريباً.'**
  String get documentsDescription;

  /// No description provided for @duesPageDescription.
  ///
  /// In ar, this message translates to:
  /// **'عرض مبسط لحالة واجبات السكن المسجلة من الإدارة.'**
  String get duesPageDescription;

  /// No description provided for @manualDuesNotice.
  ///
  /// In ar, this message translates to:
  /// **'دارجار لا يستلم الأموال. يتم الأداء خارج التطبيق وتحدّث الإدارة الحالة يدوياً.'**
  String get manualDuesNotice;

  /// No description provided for @managementPageDescription.
  ///
  /// In ar, this message translates to:
  /// **'معلومات إدارة الإقامة وطرق التواصل المتاحة.'**
  String get managementPageDescription;

  /// No description provided for @managementCompany.
  ///
  /// In ar, this message translates to:
  /// **'جهة الإدارة'**
  String get managementCompany;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get phone;

  /// No description provided for @officeHours.
  ///
  /// In ar, this message translates to:
  /// **'ساعات العمل'**
  String get officeHours;

  /// No description provided for @bankInformation.
  ///
  /// In ar, this message translates to:
  /// **'معلومات التحويل البنكي'**
  String get bankInformation;

  /// No description provided for @bank.
  ///
  /// In ar, this message translates to:
  /// **'البنك'**
  String get bank;

  /// No description provided for @bankAccount.
  ///
  /// In ar, this message translates to:
  /// **'رقم الحساب'**
  String get bankAccount;

  /// No description provided for @externalTransferNotice.
  ///
  /// In ar, this message translates to:
  /// **'يتم التحويل خارج دارجار. لا يعالج التطبيق أي دفعات.'**
  String get externalTransferNotice;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get profile;

  /// No description provided for @residenceAdministration.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الإقامة'**
  String get residenceAdministration;

  /// No description provided for @residenceSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الإقامة'**
  String get residenceSettings;

  /// No description provided for @apartments.
  ///
  /// In ar, this message translates to:
  /// **'الشقق والسكان'**
  String get apartments;

  /// No description provided for @apartmentsManagementDescription.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الشقق، إدارة السكان، تعيين الصلاحيات'**
  String get apartmentsManagementDescription;

  /// No description provided for @projects.
  ///
  /// In ar, this message translates to:
  /// **'المشاريع'**
  String get projects;

  /// No description provided for @projectsManagementDescription.
  ///
  /// In ar, this message translates to:
  /// **'المشاريع الاستثنائية، مشاريع الصيانة'**
  String get projectsManagementDescription;

  /// No description provided for @residenceManagementDescription.
  ///
  /// In ar, this message translates to:
  /// **'هيكلة الإقامة، معلومات الإقامة، قيمة الاشتراك'**
  String get residenceManagementDescription;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @residence.
  ///
  /// In ar, this message translates to:
  /// **'الإقامة'**
  String get residence;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @replayOnboarding.
  ///
  /// In ar, this message translates to:
  /// **'إعادة عرض البداية'**
  String get replayOnboarding;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @communityNotifications.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات المجتمع'**
  String get communityNotifications;

  /// No description provided for @residenceNotifications.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات الإقامة'**
  String get residenceNotifications;
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

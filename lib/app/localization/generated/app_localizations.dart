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

  /// No description provided for @marketplace.
  ///
  /// In ar, this message translates to:
  /// **'السوق'**
  String get marketplace;

  /// No description provided for @services.
  ///
  /// In ar, this message translates to:
  /// **'الخدمات'**
  String get services;

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

  /// No description provided for @marketplaceDescription.
  ///
  /// In ar, this message translates to:
  /// **'مساحة آمنة للبيع والعطاء والطلب بين سكان الإقامة.'**
  String get marketplaceDescription;

  /// No description provided for @servicesDescription.
  ///
  /// In ar, this message translates to:
  /// **'مكان موحّد للصيانة والوثائق ومعلومات إدارة الإقامة.'**
  String get servicesDescription;

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
  /// **'كل حياتك في عمارتك، في مكان واحد'**
  String get onboardingHeadline;

  /// No description provided for @onboardingDescription.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع جيرانك، تبادل الأشياء والخدمات، وتابع شؤون إقامتك بسهولة وخصوصية.'**
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

  /// No description provided for @marketplacePageDescription.
  ///
  /// In ar, this message translates to:
  /// **'بيع، أعطِ، أو اطلب من جيرانك داخل الإقامة.'**
  String get marketplacePageDescription;

  /// No description provided for @newListing.
  ///
  /// In ar, this message translates to:
  /// **'إعلان جديد'**
  String get newListing;

  /// No description provided for @offer.
  ///
  /// In ar, this message translates to:
  /// **'عرض'**
  String get offer;

  /// No description provided for @giveAway.
  ///
  /// In ar, this message translates to:
  /// **'إهداء'**
  String get giveAway;

  /// No description provided for @request.
  ///
  /// In ar, this message translates to:
  /// **'طلب'**
  String get request;

  /// No description provided for @listingNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على الإعلان.'**
  String get listingNotFound;

  /// No description provided for @contactSeller.
  ///
  /// In ar, this message translates to:
  /// **'التواصل مع المعلن'**
  String get contactSeller;

  /// No description provided for @createListing.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء إعلان في السوق'**
  String get createListing;

  /// No description provided for @createListingDescription.
  ///
  /// In ar, this message translates to:
  /// **'أضف وصفاً واضحاً حتى يفهم جيرانك ما تعرضه أو تطلبه.'**
  String get createListingDescription;

  /// No description provided for @listingTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الإعلان'**
  String get listingTitle;

  /// No description provided for @listingTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: طاولة صغيرة للبيع'**
  String get listingTitleHint;

  /// No description provided for @description.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get description;

  /// No description provided for @listingDescriptionHint.
  ///
  /// In ar, this message translates to:
  /// **'الحالة، المقاس، وطريقة الاستلام'**
  String get listingDescriptionHint;

  /// No description provided for @price.
  ///
  /// In ar, this message translates to:
  /// **'السعر أو المقابل'**
  String get price;

  /// No description provided for @priceHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: 250 درهم أو مجاناً'**
  String get priceHint;

  /// No description provided for @publishListing.
  ///
  /// In ar, this message translates to:
  /// **'نشر الإعلان'**
  String get publishListing;

  /// No description provided for @servicesPageDescription.
  ///
  /// In ar, this message translates to:
  /// **'كل ما يتعلق بخدمات وشؤون الإقامة في مكان واحد.'**
  String get servicesPageDescription;

  /// No description provided for @maintenanceRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الصيانة'**
  String get maintenanceRequests;

  /// No description provided for @maintenanceDescription.
  ///
  /// In ar, this message translates to:
  /// **'أبلغ عن مشكلة وتابع حالتها.'**
  String get maintenanceDescription;

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

  /// No description provided for @maintenancePageDescription.
  ///
  /// In ar, this message translates to:
  /// **'تابع الأعطال المشتركة والطلبات التي أرسلها السكان.'**
  String get maintenancePageDescription;

  /// No description provided for @newRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلب جديد'**
  String get newRequest;

  /// No description provided for @createMaintenanceRequest.
  ///
  /// In ar, this message translates to:
  /// **'إرسال طلب صيانة'**
  String get createMaintenanceRequest;

  /// No description provided for @createMaintenanceDescription.
  ///
  /// In ar, this message translates to:
  /// **'صف المشكلة وحدد مكانها لتسهيل معالجتها.'**
  String get createMaintenanceDescription;

  /// No description provided for @issueTitle.
  ///
  /// In ar, this message translates to:
  /// **'المشكلة'**
  String get issueTitle;

  /// No description provided for @issueTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: مصباح المدخل لا يعمل'**
  String get issueTitleHint;

  /// No description provided for @issueLocation.
  ///
  /// In ar, this message translates to:
  /// **'المكان'**
  String get issueLocation;

  /// No description provided for @issueLocationHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: العمارة A، الطابق 2'**
  String get issueLocationHint;

  /// No description provided for @submitRequest.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب'**
  String get submitRequest;

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

  /// No description provided for @servicesNotifications.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات الخدمات'**
  String get servicesNotifications;
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

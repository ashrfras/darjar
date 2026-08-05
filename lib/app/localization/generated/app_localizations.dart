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

  /// No description provided for @siteTitle.
  ///
  /// In ar, this message translates to:
  /// **'دارجار - إقامتك الرقمية'**
  String get siteTitle;

  /// No description provided for @dataLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحميل البيانات…'**
  String get dataLoading;

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
  /// **'الخدمات'**
  String get directory;

  /// No description provided for @demoResidence.
  ///
  /// In ar, this message translates to:
  /// **'إقامة الياسمين'**
  String get demoResidence;

  /// No description provided for @selectResidence.
  ///
  /// In ar, this message translates to:
  /// **'اختيار الإقامة'**
  String get selectResidence;

  /// No description provided for @residenceSwitcherDescription.
  ///
  /// In ar, this message translates to:
  /// **'اختر الإقامة التي تريد تصفحها وإدارتها الآن.'**
  String get residenceSwitcherDescription;

  /// No description provided for @currentResidence.
  ///
  /// In ar, this message translates to:
  /// **'الحالية'**
  String get currentResidence;

  /// No description provided for @acceptInvitation.
  ///
  /// In ar, this message translates to:
  /// **'انضمام'**
  String get acceptInvitation;

  /// No description provided for @residenceInvitations.
  ///
  /// In ar, this message translates to:
  /// **'دعوات الإقامة الجديدة'**
  String get residenceInvitations;

  /// No description provided for @residenceContextLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل إقامات الحساب.'**
  String get residenceContextLoadError;

  /// No description provided for @residenceDisplayName.
  ///
  /// In ar, this message translates to:
  /// **'إقامة {name}'**
  String residenceDisplayName(String name);

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
  /// **'مثال: النخيل'**
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
  /// **'كيف تريد أن تبدأ؟'**
  String get residenceSetupTitle;

  /// No description provided for @residenceSetupDescription.
  ///
  /// In ar, this message translates to:
  /// **'انضم إلى إقامتك الحالية أو أنشئ إقامة جديدة لجيرانك.'**
  String get residenceSetupDescription;

  /// No description provided for @joinMyResidence.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام إلى إقامتي'**
  String get joinMyResidence;

  /// No description provided for @joinMyResidenceDescription.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن إقامتك باستعمال الرمز الذي حصلت عليه.'**
  String get joinMyResidenceDescription;

  /// No description provided for @createNewResidence.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء إقامة جديدة'**
  String get createNewResidence;

  /// No description provided for @createNewResidenceDescription.
  ///
  /// In ar, this message translates to:
  /// **'أضف إقامتك وابدأ دعوة جيرانك إليها.'**
  String get createNewResidenceDescription;

  /// No description provided for @createResidenceFormDescription.
  ///
  /// In ar, this message translates to:
  /// **'أدخل معلومات الإقامة ومعلوماتك الأساسية للمتابعة.'**
  String get createResidenceFormDescription;

  /// No description provided for @yourInformation.
  ///
  /// In ar, this message translates to:
  /// **'معلوماتك'**
  String get yourInformation;

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

  /// No description provided for @citySelectHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر المدينة'**
  String get citySelectHint;

  /// No description provided for @cityPickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختيار المدينة'**
  String get cityPickerTitle;

  /// No description provided for @citySearchLabel.
  ///
  /// In ar, this message translates to:
  /// **'البحث عن مدينة'**
  String get citySearchLabel;

  /// No description provided for @citySearchHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم المدينة للبحث، مثال: الدار البيضاء'**
  String get citySearchHint;

  /// No description provided for @citySearchPrompt.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بكتابة اسم المدينة لتظهر النتائج.'**
  String get citySearchPrompt;

  /// No description provided for @citySearchNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لم نعثر على مدينة بهذا الاسم. جرّب كتابة اسم آخر.'**
  String get citySearchNoResults;

  /// No description provided for @cityCasablanca.
  ///
  /// In ar, this message translates to:
  /// **'الدار البيضاء'**
  String get cityCasablanca;

  /// No description provided for @cityRabat.
  ///
  /// In ar, this message translates to:
  /// **'الرباط'**
  String get cityRabat;

  /// No description provided for @cityMarrakesh.
  ///
  /// In ar, this message translates to:
  /// **'مراكش'**
  String get cityMarrakesh;

  /// No description provided for @cityTangier.
  ///
  /// In ar, this message translates to:
  /// **'طنجة'**
  String get cityTangier;

  /// No description provided for @cityAgadir.
  ///
  /// In ar, this message translates to:
  /// **'أكادير'**
  String get cityAgadir;

  /// No description provided for @cityFes.
  ///
  /// In ar, this message translates to:
  /// **'فاس'**
  String get cityFes;

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
  /// **'مثال: 48273165'**
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

  /// No description provided for @residenceAddressHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: 12 شارع الياسمين، حي المعاريف'**
  String get residenceAddressHint;

  /// No description provided for @countryCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز الدولة'**
  String get countryCode;

  /// No description provided for @countryCodePickerTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختيار رمز الدولة'**
  String get countryCodePickerTitle;

  /// No description provided for @countryGroupArab.
  ///
  /// In ar, this message translates to:
  /// **'الدول العربية'**
  String get countryGroupArab;

  /// No description provided for @countryGroupEurope.
  ///
  /// In ar, this message translates to:
  /// **'أوروبا'**
  String get countryGroupEurope;

  /// No description provided for @countryGroupNorthAmerica.
  ///
  /// In ar, this message translates to:
  /// **'أمريكا الشمالية'**
  String get countryGroupNorthAmerica;

  /// No description provided for @countryMorocco.
  ///
  /// In ar, this message translates to:
  /// **'المغرب'**
  String get countryMorocco;

  /// No description provided for @countryAlgeria.
  ///
  /// In ar, this message translates to:
  /// **'الجزائر'**
  String get countryAlgeria;

  /// No description provided for @countryTunisia.
  ///
  /// In ar, this message translates to:
  /// **'تونس'**
  String get countryTunisia;

  /// No description provided for @countryFrance.
  ///
  /// In ar, this message translates to:
  /// **'فرنسا'**
  String get countryFrance;

  /// No description provided for @countrySpain.
  ///
  /// In ar, this message translates to:
  /// **'إسبانيا'**
  String get countrySpain;

  /// No description provided for @countryUnitedStatesCanada.
  ///
  /// In ar, this message translates to:
  /// **'الولايات المتحدة وكندا'**
  String get countryUnitedStatesCanada;

  /// No description provided for @phoneNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: 06 12 34 56 78'**
  String get phoneNumberHint;

  /// No description provided for @localPhoneNumberHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: 6 12 34 56 78'**
  String get localPhoneNumberHint;

  /// No description provided for @firstName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get firstName;

  /// No description provided for @firstNameHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمك'**
  String get firstNameHint;

  /// No description provided for @lastName.
  ///
  /// In ar, this message translates to:
  /// **'النسب'**
  String get lastName;

  /// No description provided for @lastNameHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل نسبك'**
  String get lastNameHint;

  /// No description provided for @lastNamePrivacyHint.
  ///
  /// In ar, this message translates to:
  /// **'لا يتم إظهار النسب للسكان الآخرين.'**
  String get lastNamePrivacyHint;

  /// No description provided for @joinPhoneDescription.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتفك للتحقق مما إذا كان مرتبطاً بإقامة.'**
  String get joinPhoneDescription;

  /// No description provided for @verificationCodeNotice.
  ///
  /// In ar, this message translates to:
  /// **'سيتم إرسال رمز تحقق إلى رقم هاتفك.'**
  String get verificationCodeNotice;

  /// No description provided for @verificationCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق'**
  String get verificationCode;

  /// No description provided for @verificationCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل أي رمز للاختبار حالياً'**
  String get verificationCodeHint;

  /// No description provided for @verify.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق'**
  String get verify;

  /// No description provided for @phoneNotRegisteredTitle.
  ///
  /// In ar, this message translates to:
  /// **'هذا الرقم غير مسجل في أي إقامة'**
  String get phoneNotRegisteredTitle;

  /// No description provided for @phoneNotRegisteredDescription.
  ///
  /// In ar, this message translates to:
  /// **'إذا كنت قد حصلت على رابط دعوة، فيرجى الضغط عليه للانضمام إلى الإقامة.'**
  String get phoneNotRegisteredDescription;

  /// No description provided for @joinCodeDescription.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز الإقامة، أو أعد النقر على رابط الدعوة لملئه تلقائياً.'**
  String get joinCodeDescription;

  /// No description provided for @searchResidence.
  ///
  /// In ar, this message translates to:
  /// **'البحث عن الإقامة'**
  String get searchResidence;

  /// No description provided for @searchingResidence.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ البحث…'**
  String get searchingResidence;

  /// No description provided for @joinApartmentNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الشقة'**
  String get joinApartmentNumber;

  /// No description provided for @joinApartmentHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر شقتك'**
  String get joinApartmentHint;

  /// No description provided for @joinApartmentOption.
  ///
  /// In ar, this message translates to:
  /// **'الشقة {number} · {building} · {floor}'**
  String joinApartmentOption(String number, String building, String floor);

  /// No description provided for @joinNoApartments.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد شقق متاحة للاختيار في هذه الإقامة. تواصل مع المسؤول عنها.'**
  String get joinNoApartments;

  /// No description provided for @residenceCodeInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز الإقامة المكوّن من 8 أرقام.'**
  String get residenceCodeInvalid;

  /// No description provided for @residenceCodeNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لم نعثر على إقامة بهذا الرمز'**
  String get residenceCodeNotFound;

  /// No description provided for @residenceCodeNotFoundDescription.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق من الرمز مع الشخص الذي أرسله إليك ثم حاول مجدداً.'**
  String get residenceCodeNotFoundDescription;

  /// No description provided for @joinRequestsClosed.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الانضمام متوقفة حالياً في هذه الإقامة.'**
  String get joinRequestsClosed;

  /// No description provided for @sendingJoinRequest.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الانضمام…'**
  String get sendingJoinRequest;

  /// No description provided for @joinRequestSent.
  ///
  /// In ar, this message translates to:
  /// **'تم الانضمام إلى الإقامة'**
  String get joinRequestSent;

  /// No description provided for @joinRequestSentDescription.
  ///
  /// In ar, this message translates to:
  /// **'أصبحت عضويتك فعّالة ويمكنك الآن الدخول إلى محتوى الإقامة.'**
  String get joinRequestSentDescription;

  /// No description provided for @creatingResidence.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ إنشاء الإقامة…'**
  String get creatingResidence;

  /// No description provided for @setupFieldRequired.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب.'**
  String get setupFieldRequired;

  /// No description provided for @setupCompleteRequiredFields.
  ///
  /// In ar, this message translates to:
  /// **'أكمل جميع معلومات الإقامة والاسم والنسب.'**
  String get setupCompleteRequiredFields;

  /// No description provided for @setupCompleteJoinFields.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الاسم والنسب واختر رقم الشقة.'**
  String get setupCompleteJoinFields;

  /// No description provided for @setupUnexpectedError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إكمال العملية الآن. حاول مجدداً.'**
  String get setupUnexpectedError;

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

  /// No description provided for @postContent.
  ///
  /// In ar, this message translates to:
  /// **'محتوى المنشور'**
  String get postContent;

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
  /// **'دليل الخدمات المحلية التي يضيفها ويوصي بها سكان الإقامات.'**
  String get directoryPageDescription;

  /// No description provided for @directorySearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن خدمة...'**
  String get directorySearchHint;

  /// No description provided for @addService.
  ///
  /// In ar, this message translates to:
  /// **'إضافة خدمة'**
  String get addService;

  /// No description provided for @createService.
  ///
  /// In ar, this message translates to:
  /// **'إضافة خدمة جديدة'**
  String get createService;

  /// No description provided for @editService.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الخدمة'**
  String get editService;

  /// No description provided for @editServiceDescription.
  ///
  /// In ar, this message translates to:
  /// **'حدّث معلومات الخدمة التي أضفتها.'**
  String get editServiceDescription;

  /// No description provided for @createServiceDescription.
  ///
  /// In ar, this message translates to:
  /// **'أضف معلومات مقدم الخدمة لتصبح متاحة لسكان الإقامات.'**
  String get createServiceDescription;

  /// No description provided for @serviceName.
  ///
  /// In ar, this message translates to:
  /// **'اسم مقدم الخدمة'**
  String get serviceName;

  /// No description provided for @serviceNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: محمد الكهربائي أو شركة الأمان'**
  String get serviceNameHint;

  /// No description provided for @serviceCategory.
  ///
  /// In ar, this message translates to:
  /// **'الصنف الرئيسي'**
  String get serviceCategory;

  /// No description provided for @selectServiceCategory.
  ///
  /// In ar, this message translates to:
  /// **'اختر الصنف الرئيسي'**
  String get selectServiceCategory;

  /// No description provided for @serviceSubcategory.
  ///
  /// In ar, this message translates to:
  /// **'نوع الخدمة'**
  String get serviceSubcategory;

  /// No description provided for @selectServiceSubcategory.
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع الخدمة'**
  String get selectServiceSubcategory;

  /// No description provided for @selectServiceTypesHint.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك اختيار أكثر من نوع خدمة.'**
  String get selectServiceTypesHint;

  /// No description provided for @selectServiceCategoryFirst.
  ///
  /// In ar, this message translates to:
  /// **'اختر الصنف الرئيسي أولاً.'**
  String get selectServiceCategoryFirst;

  /// No description provided for @serviceDescription.
  ///
  /// In ar, this message translates to:
  /// **'وصف الخدمة'**
  String get serviceDescription;

  /// No description provided for @serviceDescriptionHint.
  ///
  /// In ar, this message translates to:
  /// **'اذكر التخصص والخدمات التي يقدمها'**
  String get serviceDescriptionHint;

  /// No description provided for @servicePhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم هاتف الخدمة'**
  String get servicePhone;

  /// No description provided for @serviceNeighborhood.
  ///
  /// In ar, this message translates to:
  /// **'الحي أو منطقة العمل'**
  String get serviceNeighborhood;

  /// No description provided for @serviceNeighborhoodOptional.
  ///
  /// In ar, this message translates to:
  /// **'الحي أو منطقة العمل (اختياري)'**
  String get serviceNeighborhoodOptional;

  /// No description provided for @serviceNeighborhoodHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: المعاريف'**
  String get serviceNeighborhoodHint;

  /// No description provided for @saveService.
  ///
  /// In ar, this message translates to:
  /// **'إضافة الخدمة'**
  String get saveService;

  /// No description provided for @updateService.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get updateService;

  /// No description provided for @savingService.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ إضافة الخدمة…'**
  String get savingService;

  /// No description provided for @updatingService.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ حفظ التعديلات…'**
  String get updatingService;

  /// No description provided for @completeServiceFields.
  ///
  /// In ar, this message translates to:
  /// **'أكمل معلومات الخدمة المطلوبة وأدخل رقم هاتف صالحًا.'**
  String get completeServiceFields;

  /// No description provided for @serviceCreated.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة الخدمة بنجاح.'**
  String get serviceCreated;

  /// No description provided for @serviceUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الخدمة بنجاح.'**
  String get serviceUpdated;

  /// No description provided for @serviceUpdateFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديث الخدمة. حاول مرة أخرى.'**
  String get serviceUpdateFailed;

  /// No description provided for @serviceCreateFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذرت إضافة الخدمة. تحقق من المعلومات وحاول مجددًا.'**
  String get serviceCreateFailed;

  /// No description provided for @noServicesYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد خدمات مضافة بعد. كن أول من يضيف خدمة موثوقة لجيرانه.'**
  String get noServicesYet;

  /// No description provided for @recommendedServicesEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر هنا الخدمات الأكثر توصية من سكان إقامتك بعد مشاركة تجاربهم.'**
  String get recommendedServicesEmptyHint;

  /// No description provided for @topServicesEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر هنا الخدمات التي جُرّبت في الإقامات وحصلت على توصيات.'**
  String get topServicesEmptyHint;

  /// No description provided for @callFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر بدء الاتصال على هذا الجهاز.'**
  String get callFailed;

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

  /// No description provided for @topRatedServices.
  ///
  /// In ar, this message translates to:
  /// **'الخدمات الأعلى توصية'**
  String get topRatedServices;

  /// No description provided for @exploreOtherServices.
  ///
  /// In ar, this message translates to:
  /// **'استكشف خدمات أخرى'**
  String get exploreOtherServices;

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
  /// **'المرفق'**
  String get supportingDocument;

  /// No description provided for @noSupportingDocument.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد وثيقة مرفقة'**
  String get noSupportingDocument;

  /// No description provided for @attachSupportingDocument.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق مستند (اختياري)'**
  String get attachSupportingDocument;

  /// No description provided for @attachmentHint.
  ///
  /// In ar, this message translates to:
  /// **'أرفق فاتورة أو إيصالًا أو أي مستند يدعم هذه المعاملة.'**
  String get attachmentHint;

  /// No description provided for @replaceAttachment.
  ///
  /// In ar, this message translates to:
  /// **'استبدال المرفق'**
  String get replaceAttachment;

  /// No description provided for @attachmentInvalid.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إرفاق الملف. اختر PDF أو صورة بحجم لا يتجاوز 15 MB.'**
  String get attachmentInvalid;

  /// No description provided for @viewAttachment.
  ///
  /// In ar, this message translates to:
  /// **'عرض المرفق'**
  String get viewAttachment;

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

  /// No description provided for @expenseCategoryCustom.
  ///
  /// In ar, this message translates to:
  /// **'مصروف مخصص'**
  String get expenseCategoryCustom;

  /// No description provided for @financeManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة مالية الإقامة'**
  String get financeManagement;

  /// No description provided for @financeManagementDescription.
  ///
  /// In ar, this message translates to:
  /// **'سجّل المداخيل الأخرى والمصاريف، وراجع مداخيل الاشتراكات المضافة تلقائياً.'**
  String get financeManagementDescription;

  /// No description provided for @manageFinanceDescription.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل مداخيل الإقامة ومصاريفها وتتبع رصيدها.'**
  String get manageFinanceDescription;

  /// No description provided for @addFinancialTransaction.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عملية'**
  String get addFinancialTransaction;

  /// No description provided for @addIncome.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مدخول آخر'**
  String get addIncome;

  /// No description provided for @addExpense.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مصروف'**
  String get addExpense;

  /// No description provided for @transactionType.
  ///
  /// In ar, this message translates to:
  /// **'نوع العملية'**
  String get transactionType;

  /// No description provided for @transactionName.
  ///
  /// In ar, this message translates to:
  /// **'اسم العملية'**
  String get transactionName;

  /// No description provided for @transactionAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get transactionAmount;

  /// No description provided for @transactionDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ العملية'**
  String get transactionDate;

  /// No description provided for @transactionNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة اختيارية'**
  String get transactionNote;

  /// No description provided for @expenseCategory.
  ///
  /// In ar, this message translates to:
  /// **'نوع المصروف'**
  String get expenseCategory;

  /// No description provided for @saveTransaction.
  ///
  /// In ar, this message translates to:
  /// **'حفظ العملية'**
  String get saveTransaction;

  /// No description provided for @financeTransactionSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل العملية المالية.'**
  String get financeTransactionSaved;

  /// No description provided for @financeTransactionUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث العملية المالية.'**
  String get financeTransactionUpdated;

  /// No description provided for @financeTransactionDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف العملية المالية.'**
  String get financeTransactionDeleted;

  /// No description provided for @financeInvalidData.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسماً ومبلغاً صحيحاً واختر نوع المصروف عند الحاجة.'**
  String get financeInvalidData;

  /// No description provided for @financeLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل بيانات مالية الإقامة. حاول مجدداً.'**
  String get financeLoadError;

  /// No description provided for @noFinancialTransactions.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عمليات مالية مسجلة.'**
  String get noFinancialTransactions;

  /// No description provided for @noExpensesRecorded.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مصاريف مسجلة خلال هذه السنة.'**
  String get noExpensesRecorded;

  /// No description provided for @manualTransaction.
  ///
  /// In ar, this message translates to:
  /// **'عملية يدوية'**
  String get manualTransaction;

  /// No description provided for @duesIncome.
  ///
  /// In ar, this message translates to:
  /// **'مدخول اشتراك'**
  String get duesIncome;

  /// No description provided for @duesIncomeForApartment.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك الشقة {apartment} عن {period}'**
  String duesIncomeForApartment(String apartment, String period);

  /// No description provided for @duesIncomeForApartmentRange.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك الشقة {apartment} عن {start} إلى {end}'**
  String duesIncomeForApartmentRange(
    String apartment,
    String start,
    String end,
  );

  /// No description provided for @editFinancialTransaction.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العملية المالية'**
  String get editFinancialTransaction;

  /// No description provided for @deleteFinancialTransaction.
  ///
  /// In ar, this message translates to:
  /// **'حذف العملية المالية'**
  String get deleteFinancialTransaction;

  /// No description provided for @confirmDeleteFinancialTransaction.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف عملية «{name}»؟ لا يمكن التراجع عن ذلك.'**
  String confirmDeleteFinancialTransaction(String name);

  /// No description provided for @financeTrackingNotice.
  ///
  /// In ar, this message translates to:
  /// **'دارجار يتتبع الأموال فقط ولا يستلمها أو يعالج أي دفعات.'**
  String get financeTrackingNotice;

  /// No description provided for @financeAutomaticDuesNotice.
  ///
  /// In ar, this message translates to:
  /// **'تُضاف أداءات الاشتراكات تلقائياً من إدارة الاشتراكات ولا يمكن تعديلها هنا.'**
  String get financeAutomaticDuesNotice;

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

  /// No description provided for @managementSettingsDescription.
  ///
  /// In ar, this message translates to:
  /// **'بيانات جهة الإدارة والتواصل والحساب البنكي.'**
  String get managementSettingsDescription;

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
  /// **'الوثائق الإدارية ومرفقات المعاملات المالية.'**
  String get documentsDescription;

  /// No description provided for @documentsPageDescription.
  ///
  /// In ar, this message translates to:
  /// **'الوثائق الإدارية ومرفقات المعاملات المالية الخاصة بالإقامة.'**
  String get documentsPageDescription;

  /// No description provided for @administrativeDocuments.
  ///
  /// In ar, this message translates to:
  /// **'الوثائق الإدارية'**
  String get administrativeDocuments;

  /// No description provided for @administrativeDocumentsDescription.
  ///
  /// In ar, this message translates to:
  /// **'الوثائق الرسمية التي ترفعها إدارة الإقامة.'**
  String get administrativeDocumentsDescription;

  /// No description provided for @attachedDocuments.
  ///
  /// In ar, this message translates to:
  /// **'الوثائق المرفقة'**
  String get attachedDocuments;

  /// No description provided for @attachedDocumentsDescription.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير والإيصالات والمستندات المرفقة بالمعاملات المالية.'**
  String get attachedDocumentsDescription;

  /// No description provided for @noAttachedDocuments.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مرفقات للمعاملات المالية بعد.'**
  String get noAttachedDocuments;

  /// No description provided for @viewAllDocuments.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل الوثائق'**
  String get viewAllDocuments;

  /// No description provided for @noDocuments.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة أي وثيقة إلى الإقامة بعد.'**
  String get noDocuments;

  /// No description provided for @documentsLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الوثائق. حاول مجدداً.'**
  String get documentsLoadError;

  /// No description provided for @pdfDocument.
  ///
  /// In ar, this message translates to:
  /// **'PDF'**
  String get pdfDocument;

  /// No description provided for @imageDocument.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get imageDocument;

  /// No description provided for @documentOpenError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح هذه الوثيقة.'**
  String get documentOpenError;

  /// No description provided for @shareDocument.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الوثيقة'**
  String get shareDocument;

  /// No description provided for @documentsManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الوثائق'**
  String get documentsManagement;

  /// No description provided for @documentsManagementDescription.
  ///
  /// In ar, this message translates to:
  /// **'رفع الوثائق الرسمية وتعديل عناوينها أو حذفها.'**
  String get documentsManagementDescription;

  /// No description provided for @documentsUploadNotice.
  ///
  /// In ar, this message translates to:
  /// **'تظهر الوثائق لجميع السكان النشطين في هذه الإقامة. الأنواع المقبولة هي PDF وJPEG وPNG وWebP بحجم أقصى 15 MB.'**
  String get documentsUploadNotice;

  /// No description provided for @documentsPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك صلاحية إدارة وثائق هذه الإقامة.'**
  String get documentsPermissionDenied;

  /// No description provided for @uploadDocument.
  ///
  /// In ar, this message translates to:
  /// **'رفع وثيقة'**
  String get uploadDocument;

  /// No description provided for @documentUploading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ رفع الوثيقة…'**
  String get documentUploading;

  /// No description provided for @documentUploadInProgress.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ رفع «{title}»'**
  String documentUploadInProgress(String title);

  /// No description provided for @documentUploadProgress.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل {percentage}% من الرفع'**
  String documentUploadProgress(int percentage);

  /// No description provided for @documentTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الوثيقة'**
  String get documentTitle;

  /// No description provided for @selectDocumentFile.
  ///
  /// In ar, this message translates to:
  /// **'اختيار صورة أو ملف PDF'**
  String get selectDocumentFile;

  /// No description provided for @documentFormRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل عنوان الوثيقة واختر ملفاً.'**
  String get documentFormRequired;

  /// No description provided for @documentTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'يجب ألا يتجاوز حجم الوثيقة 15 MB.'**
  String get documentTooLarge;

  /// No description provided for @documentUnsupportedType.
  ///
  /// In ar, this message translates to:
  /// **'النوع غير مدعوم. اختر PDF أو JPEG أو PNG أو WebP.'**
  String get documentUnsupportedType;

  /// No description provided for @documentUploaded.
  ///
  /// In ar, this message translates to:
  /// **'تم رفع الوثيقة بنجاح.'**
  String get documentUploaded;

  /// No description provided for @documentUploadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر رفع الوثيقة. حاول مجدداً.'**
  String get documentUploadError;

  /// No description provided for @editDocument.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الوثيقة'**
  String get editDocument;

  /// No description provided for @documentUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث عنوان الوثيقة.'**
  String get documentUpdated;

  /// No description provided for @documentUpdateError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديث الوثيقة.'**
  String get documentUpdateError;

  /// No description provided for @deleteDocument.
  ///
  /// In ar, this message translates to:
  /// **'حذف الوثيقة'**
  String get deleteDocument;

  /// No description provided for @confirmDeleteDocument.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف وثيقة «{title}»؟ لا يمكن التراجع عن ذلك.'**
  String confirmDeleteDocument(String title);

  /// No description provided for @documentDeleted.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف الوثيقة.'**
  String get documentDeleted;

  /// No description provided for @documentDeleteError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حذف الوثيقة.'**
  String get documentDeleteError;

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

  /// No description provided for @duesManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الاشتراكات'**
  String get duesManagement;

  /// No description provided for @duesManagementDescription.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ واجبات الشهر تلقائياً لكل شقة وسجّل الأداءات اليدوية.'**
  String get duesManagementDescription;

  /// No description provided for @duesCurrentMonth.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكات الشهر الحالي'**
  String get duesCurrentMonth;

  /// No description provided for @duesGeneratedNotice.
  ///
  /// In ar, this message translates to:
  /// **'تُنشأ الأشهر الناقصة تلقائياً حسب قيمة الاشتراك الحالية، وتُحفظ الأشهر المدفوعة مسبقاً بالقيمة نفسها.'**
  String get duesGeneratedNotice;

  /// No description provided for @duesApartmentsSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص اشتراكات الشقق'**
  String get duesApartmentsSummary;

  /// No description provided for @duesOutstandingPeriods.
  ///
  /// In ar, this message translates to:
  /// **'الأشهر غير المؤداة: {count}'**
  String duesOutstandingPeriods(int count);

  /// No description provided for @duesAllPeriodsPaid.
  ///
  /// In ar, this message translates to:
  /// **'جميع الأشهر مؤداة'**
  String get duesAllPeriodsPaid;

  /// No description provided for @duesPeriodDetailsFor.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل اشتراكات الشقة رقم {number}'**
  String duesPeriodDetailsFor(String number);

  /// No description provided for @duesSelectApartment.
  ///
  /// In ar, this message translates to:
  /// **'اختر الشقة'**
  String get duesSelectApartment;

  /// No description provided for @duesSelectApartmentError.
  ///
  /// In ar, this message translates to:
  /// **'اختر الشقة أولاً.'**
  String get duesSelectApartmentError;

  /// No description provided for @duesPaymentDistribution.
  ///
  /// In ar, this message translates to:
  /// **'سيُوزع المبلغ تلقائياً على أقدم الأشهر غير المؤداة أولاً.'**
  String get duesPaymentDistribution;

  /// No description provided for @duesAdvancePaymentHint.
  ///
  /// In ar, this message translates to:
  /// **'بعد أداء جميع المستحقات، يمكن دفع أشهر لاحقة كاملة بقيمة {amount} درهم للشهر.'**
  String duesAdvancePaymentHint(String amount);

  /// No description provided for @duesNoApartment.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم ربط حسابك بشقة بعد. تواصل مع إدارة الإقامة.'**
  String get duesNoApartment;

  /// No description provided for @duesNoRecords.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد اشتراكات مسجلة لهذه الشقة بعد.'**
  String get duesNoRecords;

  /// No description provided for @duesNoApartments.
  ///
  /// In ar, this message translates to:
  /// **'أضف الشقق أولاً حتى يتم إنشاء اشتراكات الشهر.'**
  String get duesNoApartments;

  /// No description provided for @duesApartment.
  ///
  /// In ar, this message translates to:
  /// **'الشقة رقم {number}'**
  String duesApartment(String number);

  /// No description provided for @duesPeriod.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك {period}'**
  String duesPeriod(String period);

  /// No description provided for @duesExpected.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المنتظر'**
  String get duesExpected;

  /// No description provided for @duesCollected.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المحصل'**
  String get duesCollected;

  /// No description provided for @duesRemaining.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المتبقي'**
  String get duesRemaining;

  /// No description provided for @duesDebitBalance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد المدين'**
  String get duesDebitBalance;

  /// No description provided for @duesCreditBalance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد الدائن'**
  String get duesCreditBalance;

  /// No description provided for @duesPrepaidMonths.
  ///
  /// In ar, this message translates to:
  /// **'أشهر مؤداة مسبقاً'**
  String get duesPrepaidMonths;

  /// No description provided for @duesAmountDue.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المستحق'**
  String get duesAmountDue;

  /// No description provided for @duesAmountPaid.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المؤدى'**
  String get duesAmountPaid;

  /// No description provided for @duesPaymentHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل الأداءات'**
  String get duesPaymentHistory;

  /// No description provided for @showMore.
  ///
  /// In ar, this message translates to:
  /// **'عرض المزيد'**
  String get showMore;

  /// No description provided for @duesNoPayments.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تسجيل أي أداء بعد.'**
  String get duesNoPayments;

  /// No description provided for @duesStatusUnpaid.
  ///
  /// In ar, this message translates to:
  /// **'غير مؤدى'**
  String get duesStatusUnpaid;

  /// No description provided for @duesStatusPartial.
  ///
  /// In ar, this message translates to:
  /// **'مؤدى جزئياً'**
  String get duesStatusPartial;

  /// No description provided for @duesStatusPaid.
  ///
  /// In ar, this message translates to:
  /// **'مؤدى'**
  String get duesStatusPaid;

  /// No description provided for @duesRecordPayment.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل أداء'**
  String get duesRecordPayment;

  /// No description provided for @duesRecordPaymentFor.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل أداء للشقة رقم {number}'**
  String duesRecordPaymentFor(String number);

  /// No description provided for @duesPaymentAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المؤدى'**
  String get duesPaymentAmount;

  /// No description provided for @duesPaymentDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الأداء'**
  String get duesPaymentDate;

  /// No description provided for @duesPaymentNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة اختيارية'**
  String get duesPaymentNote;

  /// No description provided for @duesSavePayment.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الأداء'**
  String get duesSavePayment;

  /// No description provided for @duesPaymentSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الأداء بنجاح.'**
  String get duesPaymentSaved;

  /// No description provided for @duesInvalidPayment.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مبلغاً صحيحاً. يجب أن يساوي الجزء المدفوع مسبقاً قيمة شهر كامل أو عدة أشهر.'**
  String get duesInvalidPayment;

  /// No description provided for @duesLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل بيانات الاشتراكات. حاول مجدداً.'**
  String get duesLoadError;

  /// No description provided for @duesRecordedOn.
  ///
  /// In ar, this message translates to:
  /// **'سُجّل بتاريخ {date}'**
  String duesRecordedOn(String date);

  /// No description provided for @managementPageDescription.
  ///
  /// In ar, this message translates to:
  /// **'معلومات إدارة الإقامة وطرق التواصل المتاحة.'**
  String get managementPageDescription;

  /// No description provided for @residenceBuildingCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد العمارات'**
  String get residenceBuildingCount;

  /// No description provided for @residenceApartmentCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الشقق'**
  String get residenceApartmentCount;

  /// No description provided for @residenceConstructionYear.
  ///
  /// In ar, this message translates to:
  /// **'سنة البناء'**
  String get residenceConstructionYear;

  /// No description provided for @residenceResidents.
  ///
  /// In ar, this message translates to:
  /// **'سكان الإقامة'**
  String get residenceResidents;

  /// No description provided for @residenceResidentsDescription.
  ///
  /// In ar, this message translates to:
  /// **'تعرّف على جيرانك وبيانات السكن داخل الإقامة.'**
  String get residenceResidentsDescription;

  /// No description provided for @residenceResidentsCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد السكان: {count}'**
  String residenceResidentsCount(int count);

  /// No description provided for @residenceNoResidents.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد سكان مسجلون في هذه الإقامة بعد.'**
  String get residenceNoResidents;

  /// No description provided for @residenceResidentsLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل قائمة سكان الإقامة. حاول مجدداً.'**
  String get residenceResidentsLoadError;

  /// No description provided for @residentApartment.
  ///
  /// In ar, this message translates to:
  /// **'الشقة {number}'**
  String residentApartment(String number);

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

  /// No description provided for @bankName.
  ///
  /// In ar, this message translates to:
  /// **'اسم البنك'**
  String get bankName;

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

  /// No description provided for @profileResidences.
  ///
  /// In ar, this message translates to:
  /// **'الإقامات'**
  String get profileResidences;

  /// No description provided for @profileNoResidences.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إقامات مرتبطة بهذا الحساب.'**
  String get profileNoResidences;

  /// No description provided for @profileApartmentNumber.
  ///
  /// In ar, this message translates to:
  /// **'الشقة رقم {number}'**
  String profileApartmentNumber(String number);

  /// No description provided for @profileApartmentNotAssigned.
  ///
  /// In ar, this message translates to:
  /// **'لم تُحدّد الشقة بعد'**
  String get profileApartmentNotAssigned;

  /// No description provided for @profileNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الاسم والنسب.'**
  String get profileNameRequired;

  /// No description provided for @profileSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ معلومات الحساب.'**
  String get profileSaved;

  /// No description provided for @profileSaving.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الحفظ…'**
  String get profileSaving;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @signOutConfirmationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج؟'**
  String get signOutConfirmationTitle;

  /// No description provided for @signOutConfirmationDescription.
  ///
  /// In ar, this message translates to:
  /// **'ستحتاج إلى تسجيل الدخول مجدداً للوصول إلى حسابك وإقاماتك.'**
  String get signOutConfirmationDescription;

  /// No description provided for @signingOut.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تسجيل الخروج…'**
  String get signingOut;

  /// No description provided for @signOutFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تسجيل الخروج. حاول مجدداً.'**
  String get signOutFailed;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @editProfileName.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الاسم والنسب'**
  String get editProfileName;

  /// No description provided for @editProfileNameDescription.
  ///
  /// In ar, this message translates to:
  /// **'حدّث الاسم الذي يظهر لجيرانك في الإقامات.'**
  String get editProfileNameDescription;

  /// No description provided for @profileRolePresident.
  ///
  /// In ar, this message translates to:
  /// **'رئيس'**
  String get profileRolePresident;

  /// No description provided for @profileRoleDeputy.
  ///
  /// In ar, this message translates to:
  /// **'نائب'**
  String get profileRoleDeputy;

  /// No description provided for @profileRoleTreasurer.
  ///
  /// In ar, this message translates to:
  /// **'أمين'**
  String get profileRoleTreasurer;

  /// No description provided for @profileRoleResident.
  ///
  /// In ar, this message translates to:
  /// **'ساكن'**
  String get profileRoleResident;

  /// No description provided for @residenceAdministration.
  ///
  /// In ar, this message translates to:
  /// **'الإدارة'**
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
  /// **'إدارة الشقق وتوزيع السكان داخل الإقامة'**
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

  /// No description provided for @generalSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات العامة'**
  String get generalSettings;

  /// No description provided for @professionalSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات الاحترافية'**
  String get professionalSettings;

  /// No description provided for @professionalAccountDescription.
  ///
  /// In ar, this message translates to:
  /// **'من أجل إدارة إقامات متعددة، يرجى التبديل إلى الحساب الاحترافي.'**
  String get professionalAccountDescription;

  /// No description provided for @switchToProfessionalAccount.
  ///
  /// In ar, this message translates to:
  /// **'التبديل إلى الحساب الاحترافي'**
  String get switchToProfessionalAccount;

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

  /// No description provided for @markAllNotificationsRead.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل كمقروء'**
  String get markAllNotificationsRead;

  /// No description provided for @noNotifications.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات حاليًا.'**
  String get noNotifications;

  /// No description provided for @notificationsLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الإشعارات.'**
  String get notificationsLoadError;

  /// No description provided for @newPostNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'منشور جديد'**
  String get newPostNotificationTitle;

  /// No description provided for @newPostNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'أضاف {author} منشورًا جديدًا.'**
  String newPostNotificationBody(String author);

  /// No description provided for @postLikedNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعجاب جديد'**
  String get postLikedNotificationTitle;

  /// No description provided for @postLikedNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'أُعجب {actor} بمنشورك.'**
  String postLikedNotificationBody(String actor);

  /// No description provided for @postCommentedNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعليق جديد'**
  String get postCommentedNotificationTitle;

  /// No description provided for @postCommentedNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'علّق {actor} على منشورك.'**
  String postCommentedNotificationBody(String actor);

  /// No description provided for @duesOverdueNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأخر الأداء'**
  String get duesOverdueNotificationTitle;

  /// No description provided for @duesOverdueNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'تأخر أداء واجب الفترة {period}.'**
  String duesOverdueNotificationBody(String period);

  /// No description provided for @budgetChangedNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الميزانية'**
  String get budgetChangedNotificationTitle;

  /// No description provided for @budgetChangedNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث ميزانية الإقامة.'**
  String get budgetChangedNotificationBody;

  /// No description provided for @duesMarkedPaidNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل أداء اشتراكك'**
  String get duesMarkedPaidNotificationTitle;

  /// No description provided for @duesMarkedPaidNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل اشتراكك عن الفترة {period} كمؤدى.'**
  String duesMarkedPaidNotificationBody(String period);

  /// No description provided for @waterInterruptionNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'انقطاع مبرمج للماء'**
  String get waterInterruptionNotificationTitle;

  /// No description provided for @waterInterruptionNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'سيتم قطع الماء غداً من 6 إلى 10 صباحاً لأشغال الصيانة.'**
  String get waterInterruptionNotificationBody;

  /// No description provided for @duesReminderNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تذكير بواجبات الإقامة'**
  String get duesReminderNotificationTitle;

  /// No description provided for @duesReminderNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'يرجى مراجعة حالة واجبات هذا الشهر في صفحة الإقامة.'**
  String get duesReminderNotificationBody;

  /// No description provided for @maintenanceNotificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'صيانة المصعد'**
  String get maintenanceNotificationTitle;

  /// No description provided for @maintenanceNotificationBody.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت صيانة المصعد وأصبح متاحاً للاستعمال.'**
  String get maintenanceNotificationBody;

  /// No description provided for @notificationTimeNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get notificationTimeNow;

  /// No description provided for @notificationTimeMinutes.
  ///
  /// In ar, this message translates to:
  /// **'منذ {minutes} د'**
  String notificationTimeMinutes(int minutes);

  /// No description provided for @notificationTimeHours.
  ///
  /// In ar, this message translates to:
  /// **'منذ {hours} س'**
  String notificationTimeHours(int hours);

  /// No description provided for @notificationTimeYesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get notificationTimeYesterday;

  /// No description provided for @notificationTimeDays.
  ///
  /// In ar, this message translates to:
  /// **'منذ {days} أيام'**
  String notificationTimeDays(int days);

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

  /// No description provided for @importantNotifications.
  ///
  /// In ar, this message translates to:
  /// **'إشعارات هامة'**
  String get importantNotifications;

  /// No description provided for @duesMarkedPaidNotification.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل مستحقات {period} كمؤداة'**
  String duesMarkedPaidNotification(String period);

  /// No description provided for @overdueDuesNotification.
  ///
  /// In ar, this message translates to:
  /// **'مستحقات {period} متأخرة'**
  String overdueDuesNotification(String period);

  /// No description provided for @membershipApprovedNotification.
  ///
  /// In ar, this message translates to:
  /// **'وافق الرئيس على طلب انضمامك إلى الإقامة'**
  String get membershipApprovedNotification;

  /// No description provided for @residenceSettingsPageDescription.
  ///
  /// In ar, this message translates to:
  /// **'تحكّم في معلومات الإقامة وهيكلها والاشتراك.'**
  String get residenceSettingsPageDescription;

  /// No description provided for @saveChanges.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التغييرات'**
  String get saveChanges;

  /// No description provided for @residenceInformation.
  ///
  /// In ar, this message translates to:
  /// **'معلومات الإقامة'**
  String get residenceInformation;

  /// No description provided for @residenceInformationDescription.
  ///
  /// In ar, this message translates to:
  /// **'البيانات الأساسية التي تظهر لسكان الإقامة.'**
  String get residenceInformationDescription;

  /// No description provided for @residenceId.
  ///
  /// In ar, this message translates to:
  /// **'معرّف الإقامة'**
  String get residenceId;

  /// No description provided for @copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copy;

  /// No description provided for @residenceIdCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ معرّف الإقامة.'**
  String get residenceIdCopied;

  /// No description provided for @residenceImage.
  ///
  /// In ar, this message translates to:
  /// **'صورة أو شعار الإقامة'**
  String get residenceImage;

  /// No description provided for @squareImageRecommended.
  ///
  /// In ar, this message translates to:
  /// **'يفضّل اختيار صورة مربعة للحصول على أفضل عرض.'**
  String get squareImageRecommended;

  /// No description provided for @addImage.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صورة'**
  String get addImage;

  /// No description provided for @changeImage.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الصورة'**
  String get changeImage;

  /// No description provided for @removeImage.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الصورة'**
  String get removeImage;

  /// No description provided for @imageProcessingFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر اختيار الصورة أو معالجتها. اختر JPG أو PNG أو WebP بحجم أقل من 8MB.'**
  String get imageProcessingFailed;

  /// No description provided for @imageUploadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر رفع الصورة. تحقق من الاتصال والصلاحيات ثم حاول مجددًا.'**
  String get imageUploadFailed;

  /// No description provided for @profileImageSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث صورة البروفايل.'**
  String get profileImageSaved;

  /// No description provided for @profileImageRemoved.
  ///
  /// In ar, this message translates to:
  /// **'تمت إزالة صورة البروفايل.'**
  String get profileImageRemoved;

  /// No description provided for @address.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get address;

  /// No description provided for @establishmentYear.
  ///
  /// In ar, this message translates to:
  /// **'سنة التأسيس'**
  String get establishmentYear;

  /// No description provided for @residenceStructure.
  ///
  /// In ar, this message translates to:
  /// **'هيكل الإقامة'**
  String get residenceStructure;

  /// No description provided for @residenceStructureDescription.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ مباني الإقامة وحدد اسماً وعدد الطوابق لكل مبنى.'**
  String get residenceStructureDescription;

  /// No description provided for @buildings.
  ///
  /// In ar, this message translates to:
  /// **'البنايات'**
  String get buildings;

  /// No description provided for @floors.
  ///
  /// In ar, this message translates to:
  /// **'الطوابق'**
  String get floors;

  /// No description provided for @manageStructure.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الهيكل'**
  String get manageStructure;

  /// No description provided for @buildingName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المبنى'**
  String get buildingName;

  /// No description provided for @buildingNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: جناح أ'**
  String get buildingNameHint;

  /// No description provided for @floorCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الطوابق'**
  String get floorCount;

  /// No description provided for @buildingFloorCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الطوابق: {count}'**
  String buildingFloorCount(int count);

  /// No description provided for @addBuilding.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مبنى'**
  String get addBuilding;

  /// No description provided for @editBuilding.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المبنى'**
  String get editBuilding;

  /// No description provided for @deleteBuilding.
  ///
  /// In ar, this message translates to:
  /// **'حذف المبنى'**
  String get deleteBuilding;

  /// No description provided for @atLeastOneBuilding.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن تحتوي الإقامة على مبنى واحد على الأقل.'**
  String get atLeastOneBuilding;

  /// No description provided for @checkBuildingFields.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسم المبنى وعدد طوابق صحيحاً.'**
  String get checkBuildingFields;

  /// No description provided for @structureContainsApartments.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن حذف مبنى أو طابق يحتوي على شقق. احذف الشقق أولاً.'**
  String get structureContainsApartments;

  /// No description provided for @confirmDeleteBuilding.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف {name} من هيكل الإقامة؟'**
  String confirmDeleteBuilding(String name);

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @subscription.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك'**
  String get subscription;

  /// No description provided for @subscriptionDescription.
  ///
  /// In ar, this message translates to:
  /// **'حدّد القيمة الافتراضية لاشتراك سكان الإقامة.'**
  String get subscriptionDescription;

  /// No description provided for @defaultSubscription.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك الافتراضي'**
  String get defaultSubscription;

  /// No description provided for @monthly.
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get monthly;

  /// No description provided for @amount.
  ///
  /// In ar, this message translates to:
  /// **'القيمة'**
  String get amount;

  /// No description provided for @joiningResidence.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام للإقامة'**
  String get joiningResidence;

  /// No description provided for @joiningResidenceDescription.
  ///
  /// In ar, this message translates to:
  /// **'شارك الدعوة وتحكّم في استقبال طلبات السكان الجدد.'**
  String get joiningResidenceDescription;

  /// No description provided for @permanentInvitationLink.
  ///
  /// In ar, this message translates to:
  /// **'رابط الدعوة الدائم'**
  String get permanentInvitationLink;

  /// No description provided for @copyLink.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الرابط'**
  String get copyLink;

  /// No description provided for @showQrCode.
  ///
  /// In ar, this message translates to:
  /// **'عرض رمز QR'**
  String get showQrCode;

  /// No description provided for @hideQrCode.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء رمز QR'**
  String get hideQrCode;

  /// No description provided for @invitationQrCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز دعوة الإقامة'**
  String get invitationQrCode;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @scanToJoin.
  ///
  /// In ar, this message translates to:
  /// **'امسح الرمز للانضمام'**
  String get scanToJoin;

  /// No description provided for @allowJoinRequests.
  ///
  /// In ar, this message translates to:
  /// **'السماح بطلبات انضمام جديدة'**
  String get allowJoinRequests;

  /// No description provided for @joinRequestsEnabledDescription.
  ///
  /// In ar, this message translates to:
  /// **'يمكن للسكان الجدد إرسال طلب للانضمام.'**
  String get joinRequestsEnabledDescription;

  /// No description provided for @joinRequestsDisabledDescription.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الانضمام الجديدة متوقفة حالياً.'**
  String get joinRequestsDisabledDescription;

  /// No description provided for @invitationExplorationNotice.
  ///
  /// In ar, this message translates to:
  /// **'يبقى الرابط صالحاً لاستكشاف الإقامة على الويب، لكن لا يمكن إرسال طلب انضمام جديد.'**
  String get invitationExplorationNotice;

  /// No description provided for @invitationLinkCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ رابط الدعوة.'**
  String get invitationLinkCopied;

  /// No description provided for @residenceSettingsSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ إعدادات الإقامة.'**
  String get residenceSettingsSaved;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم حفظ التعديلات'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesDescription.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم حفظ التعديلات التي أجريتها. هل تريد حفظها قبل العودة؟'**
  String get unsavedChangesDescription;

  /// No description provided for @discardChanges.
  ///
  /// In ar, this message translates to:
  /// **'العودة دون حفظ'**
  String get discardChanges;

  /// No description provided for @checkResidenceSettingsFields.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق من معلومات الإقامة وقيمة الاشتراك.'**
  String get checkResidenceSettingsFields;

  /// No description provided for @authPhoneTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول برقم هاتفك'**
  String get authPhoneTitle;

  /// No description provided for @authPhoneDescription.
  ///
  /// In ar, this message translates to:
  /// **'سنرسل إليك رمزاً قصيراً للتحقق من رقم الهاتف وحماية حسابك.'**
  String get authPhoneDescription;

  /// No description provided for @authPhoneHint.
  ///
  /// In ar, this message translates to:
  /// **'0600000001'**
  String get authPhoneHint;

  /// No description provided for @authSendCode.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رمز التحقق'**
  String get authSendCode;

  /// No description provided for @authSendingCode.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ إرسال الرمز…'**
  String get authSendingCode;

  /// No description provided for @authCodeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التحقق'**
  String get authCodeTitle;

  /// No description provided for @authCodeDescription.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز المكوّن من 6 أرقام المرسل إلى {phoneNumber}.'**
  String authCodeDescription(String phoneNumber);

  /// No description provided for @authCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'6 أرقام'**
  String get authCodeHint;

  /// No description provided for @authVerifying.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق…'**
  String get authVerifying;

  /// No description provided for @authResendCode.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الرمز'**
  String get authResendCode;

  /// No description provided for @authResendCodeIn.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الرمز بعد {seconds} ثانية'**
  String authResendCodeIn(int seconds);

  /// No description provided for @authChangePhone.
  ///
  /// In ar, this message translates to:
  /// **'تغيير رقم الهاتف'**
  String get authChangePhone;

  /// No description provided for @authPrivacyNotice.
  ///
  /// In ar, this message translates to:
  /// **'يُستخدم رقم هاتفك لتسجيل الدخول وحماية حسابك وفق سياسة الخصوصية.'**
  String get authPrivacyNotice;

  /// No description provided for @authInvalidPhone.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتف صحيحاً.'**
  String get authInvalidPhone;

  /// No description provided for @authInvalidCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق غير صحيح. راجع الرمز وحاول مجدداً.'**
  String get authInvalidCode;

  /// No description provided for @authCodeExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الرمز. اطلب رمزاً جديداً.'**
  String get authCodeExpired;

  /// No description provided for @authTooManyRequests.
  ///
  /// In ar, this message translates to:
  /// **'تمت محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.'**
  String get authTooManyRequests;

  /// No description provided for @authNetworkError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال. تحقق من الإنترنت وحاول مجدداً.'**
  String get authNetworkError;

  /// No description provided for @authUnauthorizedDomain.
  ///
  /// In ar, this message translates to:
  /// **'هذا النطاق غير مسموح له بتسجيل الدخول. أضفه إلى النطاقات المعتمدة في Firebase Authentication.'**
  String get authUnauthorizedDomain;

  /// No description provided for @authCaptchaFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إكمال التحقق الأمني. أعد المحاولة وأكمل اختبار reCAPTCHA.'**
  String get authCaptchaFailed;

  /// No description provided for @authPhoneOperationNotAllowed.
  ///
  /// In ar, this message translates to:
  /// **'عملية تسجيل الدخول بالهاتف غير مسموحة. تحقّق من السماح للمغرب في سياسة مناطق SMS وربط المشروع بحساب فوترة.'**
  String get authPhoneOperationNotAllowed;

  /// No description provided for @authUnexpectedError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تسجيل الدخول الآن. حاول مجدداً.'**
  String get authUnexpectedError;

  /// No description provided for @accountResolutionTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد معلوماتك'**
  String get accountResolutionTitle;

  /// No description provided for @accountResolutionDescription.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق من معلوماتك، ثم اختر الإقامات التي تنتمي إليها.'**
  String get accountResolutionDescription;

  /// No description provided for @accountResolutionFullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get accountResolutionFullName;

  /// No description provided for @accountResolutionInvitationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تمت دعوتك إلى هذه الإقامات'**
  String get accountResolutionInvitationsTitle;

  /// No description provided for @accountResolutionInvitationsDescription.
  ///
  /// In ar, this message translates to:
  /// **'علّم الإقامات التي تنتمي إليها. ستبقى الدعوات غير المحددة معلّقة لتراجعها لاحقاً.'**
  String get accountResolutionInvitationsDescription;

  /// No description provided for @accountResolutionRole.
  ///
  /// In ar, this message translates to:
  /// **'الصفة: {role}'**
  String accountResolutionRole(String role);

  /// No description provided for @accountRoleResident.
  ///
  /// In ar, this message translates to:
  /// **'ساكن'**
  String get accountRoleResident;

  /// No description provided for @accountRoleModerator.
  ///
  /// In ar, this message translates to:
  /// **'أمين'**
  String get accountRoleModerator;

  /// No description provided for @accountRoleManager.
  ///
  /// In ar, this message translates to:
  /// **'نائب'**
  String get accountRoleManager;

  /// No description provided for @accountRoleOwner.
  ///
  /// In ar, this message translates to:
  /// **'رئيس'**
  String get accountRoleOwner;

  /// No description provided for @accountResolutionConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد والانضمام إلى الإقامات المحددة'**
  String get accountResolutionConfirm;

  /// No description provided for @accountResolutionAccepting.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تأكيد العضوية…'**
  String get accountResolutionAccepting;

  /// No description provided for @accountResolutionPendingNotice.
  ///
  /// In ar, this message translates to:
  /// **'لن تُرفض الإقامات غير المحددة، وستبقى دعواتها معلّقة.'**
  String get accountResolutionPendingNotice;

  /// No description provided for @accountResolutionRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get accountResolutionRetry;

  /// No description provided for @accountResolutionPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'لا تسمح قواعد قاعدة البيانات بقراءة هذه الدعوات أو قبولها. انشر قواعد Firestore الجديدة ثم حاول مجدداً.'**
  String get accountResolutionPermissionDenied;

  /// No description provided for @accountResolutionFailedPrecondition.
  ///
  /// In ar, this message translates to:
  /// **'فهرس قاعدة البيانات المطلوب غير جاهز بعد. انتظر اكتمال بنائه ثم حاول مجدداً.'**
  String get accountResolutionFailedPrecondition;

  /// No description provided for @accountResolutionMissingProfile.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الاسم أو النسب في الدعوة غير مكتملة.'**
  String get accountResolutionMissingProfile;

  /// No description provided for @accountResolutionSignedOut.
  ///
  /// In ar, this message translates to:
  /// **'انتهت جلسة تسجيل الدخول. سجّل الدخول مجدداً.'**
  String get accountResolutionSignedOut;

  /// No description provided for @accountResolutionUnexpectedError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الدعوات أو تأكيدها الآن. حاول مجدداً.'**
  String get accountResolutionUnexpectedError;
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

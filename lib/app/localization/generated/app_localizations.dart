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

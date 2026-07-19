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
  String get foundationTitle => 'الأساس جاهز';

  @override
  String get foundationDescription =>
      'تطبيق واحد للجوال والويب، جاهز للعربية من البداية.';

  @override
  String windowSizeLabel(String size) {
    return 'حجم النافذة: $size';
  }

  @override
  String get compactSize => 'صغير';

  @override
  String get mediumSize => 'متوسط';

  @override
  String get expandedSize => 'واسع';
}

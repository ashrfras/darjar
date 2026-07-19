// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'DarJar';

  @override
  String get foundationTitle => 'Foundation ready';

  @override
  String get foundationDescription =>
      'One application for mobile and web, ready for Arabic from day one.';

  @override
  String windowSizeLabel(String size) {
    return 'Window size: $size';
  }

  @override
  String get compactSize => 'compact';

  @override
  String get mediumSize => 'medium';

  @override
  String get expandedSize => 'expanded';
}

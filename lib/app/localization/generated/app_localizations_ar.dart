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
  String get marketplace => 'السوق';

  @override
  String get services => 'الخدمات';

  @override
  String get demoResidence => 'إقامة الياسمين';

  @override
  String get communityDescription =>
      'مساحة أخبار الجيران والإعلانات والنقاشات داخل الإقامة.';

  @override
  String get marketplaceDescription =>
      'مساحة آمنة للبيع والعطاء والطلب بين سكان الإقامة.';

  @override
  String get servicesDescription =>
      'مكان موحّد للصيانة والوثائق ومعلومات إدارة الإقامة.';

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
  String get residenceNameHint => 'مثال: إقامة الياسمين';

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
}

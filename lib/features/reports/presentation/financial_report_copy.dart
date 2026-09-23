import 'package:darjar/features/residence/data/residence_finance_repository.dart';

class FinancialReportCopy {
  const FinancialReportCopy(
    this.arabic, {
    this.statement = false,
    this.apartmentDues = false,
    this.monthlyDues = false,
  });
  final bool statement;
  final bool apartmentDues;
  final bool monthlyDues;
  final bool arabic;
  String get locale => arabic ? 'ar' : 'en';
  String t(String ar, String en) => arabic ? ar : en;
  String get reports => t('التقارير', 'Reports');
  String get title => monthlyDues
      ? t('تتبع أداء الواجبات حسب الأشهر', 'Monthly dues tracking')
      : apartmentDues
      ? t('وضعية واجبات الشقق', 'Apartment dues status')
      : statement
      ? t('كشف الحساب', 'Account statement')
      : t('التقرير المالي', 'Financial report');
  String get pdfTitle => (statement || apartmentDues || monthlyDues)
      ? title
      : t('ملخص التقرير المالي', 'Financial report summary');
  String get reportsDescription => t(
    'استخراج تقارير الإقامة واستعراضها ومشاركتها.',
    'Generate, review, and share residence reports.',
  );
  String get description => monthlyDues
      ? t(
          'جدول سنوي لحالة أداء كل شهر لكل شقة.',
          'Annual table of monthly payment status for each apartment.',
        )
      : apartmentDues
      ? t(
          'إجماليات المستحق والمحصل والمتبقي والمتأخرات السابقة.',
          'Totals for dues, collections, outstanding amounts, and prior arrears.',
        )
      : statement
      ? t(
          'كشف تفصيلي لمداخيل ومصاريف الإقامة خلال الفترة المختارة.',
          'Detailed residence income and expenses for the selected period.',
        )
      : t(
          'عرض الأرصدة والمداخيل والمصاريف وتحصيل الواجبات خلال فترة محددة.',
          'Review balances, income, expenses, and dues collection for a selected period.',
        );
  String get apartmentDuesBasis => t(
    'يشمل جميع الشقق والواجبات المسجلة فقط. المستحق والمحصل والمتبقي تخص أشهر الفترة كاملة؛ المتأخرات السابقة تخص الأشهر الأقدم، والأداءات محسوبة حتى نهاية الفترة. الإعفاءات وحالة التتبع حسب السجلات الحالية.',
    'Includes every apartment and recorded dues only. Due, collected, and outstanding amounts cover full selected months; prior arrears cover older months. Payments are counted through period end. Exemptions and tracking status reflect current records.',
  );
  String get monthlyDuesBasis => t(
    'يعرض حالة الأداء الحالية لأشهر السنة المختارة، حتى تاريخ إعداد التقرير. الأعداد والمتبقي تشمل الأشهر السابقة للسنة؛ الأشهر اللاحقة لا تُحتسب كديون. غياب السجلات لا يعني عدم الأداء.',
    'Shows current payment status for the selected year as of report generation. Counts and balances include prior-year arrears; future months are not debts. Missing records do not mean nonpayment.',
  );
  String get opening => t('رصيد بداية الفترة', 'Opening balance');
  String get closing => t('رصيد نهاية الفترة', 'Closing balance');
  String get income => t('مداخيل الفترة', 'Period income');
  String get expenses => t('مصاريف الفترة', 'Period expenses');
  String get dues => t('واجبات الإقامة', 'Residence dues');
  String get expected => t('المستحق عن أشهر الفترة', 'Due for selected months');
  String get collected =>
      t('المحصل حتى نهاية الفترة', 'Collected by period end');
  String get unpaid =>
      t('المتبقي عن أشهر الفترة', 'Unpaid for selected months');
  String get arrears =>
      t('إجمالي المتأخرات حتى نهاية الفترة', 'Total arrears at period end');
  String get rate => t('نسبة التحصيل', 'Collection rate');
  String get sources => t('مصادر المداخيل', 'Income sources');
  String get otherIncome => t('مداخيل أخرى', 'Other income');
  String get categories => t('المصاريف حسب الفئة', 'Expenses by category');
  String get notes => t('حول هذا التقرير', 'About this report');
  String get basis => t(
    'المداخيل والمصاريف حسب تاريخ العملية، من أول يوم إلى نهاية آخر يوم في الفترة.',
    'Cash movements follow transaction dates, including both boundary days.',
  );
  String get duesBasis => t(
    'الواجبات تخص الأشهر المشمولة كاملة دون تجزئة؛ التحصيل والمتأخرات محسوبان حتى نهاية الفترة.',
    'Dues cover full selected months without proration; collections and arrears are measured at period end.',
  );
  String get scope => t(
    'في حال ملاحظة أي خطأ أو عدم تطابق في بيانات هذا التقرير، يُرجى التواصل مع رئيس الاتحاد للتحقق واتخاذ ما يلزم من تصحيح.',
    'If you notice an error or discrepancy in this report, please contact the union president for verification and any necessary correction.',
  );
  String get missingOpening => t(
    'لم يُسجّل رصيد افتتاحي؛ الأرصدة محسوبة من العمليات المسجلة فقط.',
    'No initial balance is recorded; balances reflect recorded transactions only.',
  );
  String get introduced =>
      t('رصيد افتتاحي مسجل داخل الفترة', 'Initial balance entered in period');
  String get emptyExpenses => t(
    'لا توجد مصاريف مسجلة خلال الفترة.',
    'No expenses recorded in this period.',
  );
  String get generate => t('معاينة التقرير', 'Preview report');
  String get download => t('تحميل أو مشاركة PDF', 'Download or share PDF');
  String get error => t(
    'تعذر إعداد التقرير. حاول مجددًا.',
    'Could not prepare the report. Please retry.',
  );
  String category(ResidenceExpenseCategory category) => switch (category) {
    ResidenceExpenseCategory.maintenance => t('الصيانة', 'Maintenance'),
    ResidenceExpenseCategory.utilities => t('الماء والكهرباء', 'Utilities'),
    ResidenceExpenseCategory.cleaning => t('النظافة', 'Cleaning'),
    ResidenceExpenseCategory.security => t('الحراسة', 'Security'),
    ResidenceExpenseCategory.custom => t('مصاريف أخرى', 'Other expenses'),
  };
}

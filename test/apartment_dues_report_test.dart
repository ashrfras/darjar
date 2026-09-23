import 'dart:io';

import 'package:darjar/features/reports/domain/apartment_dues_report.dart';
import 'package:darjar/features/reports/presentation/apartment_dues_report_document.dart';
import 'package:darjar/features/reports/presentation/financial_report_copy.dart';
import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

ResidenceApartment apartment(String number, {bool active = true}) =>
    ResidenceApartment(
      id: number,
      number: number,
      floorId: 'f',
      duesTrackingStatus: active
          ? ResidenceDuesTrackingStatus.active
          : ResidenceDuesTrackingStatus.notStarted,
    );
ResidenceDue due(
  String id,
  String apartment,
  String period, {
  bool exempt = false,
}) => ResidenceDue(
  id: id,
  apartmentId: apartment,
  apartmentNumber: apartment,
  periodKey: period,
  amountDue: 200,
  amountPaid: 200,
  status: exempt ? ResidenceDueStatus.exempt : ResidenceDueStatus.paid,
);
ResidenceDuePayment payment(String id, int amount, DateTime date) =>
    ResidenceDuePayment(
      id: '$id-$date',
      dueId: id,
      apartmentId: '2',
      apartmentNumber: '2',
      amount: amount,
      paidAt: date,
      note: '',
      recordedBy: '',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });
  ApartmentDuesReport sample() => ApartmentDuesReport(
    from: DateTime(2026, 3, 12),
    to: DateTime(2026, 3, 31),
    apartments: [
      apartment('10'),
      apartment('2'),
      apartment('3'),
      apartment('4', active: false),
      apartment('5'),
    ],
    dues: ResidenceDuesOverview(
      dues: [
        due('old', '2', '2026-02'),
        due('march', '2', '2026-03'),
        due('future', '2', '2026-04'),
        due('exempt', '3', '2026-03', exempt: true),
        due('paid', '5', '2026-03'),
      ],
      payments: [
        payment('old', 50, DateTime(2026, 3)),
        payment('march', 80, DateTime(2026, 3, 31, 23, 59)),
        payment('march', 120, DateTime(2026, 4)),
        payment('paid', 200, DateTime(2026, 2)),
      ],
    ),
  );

  test(
    'all apartments, numeric order, exemptions, prior arrears and payment cutoff',
    () {
      final report = sample();
      expect(report.rows.map((r) => r.apartment.number), [
        '2',
        '3',
        '4',
        '5',
        '10',
      ]);
      expect(report.expected, 400);
      expect(report.collected, 280);
      expect(report.unpaid, 120);
      expect(report.previousUnpaid, 150);
      expect(report.totalUnpaid, 270);
      const copy = FinancialReportCopy(true, apartmentDues: true);
      expect(report.rows.map((r) => apartmentDuesReportStatus(r, copy)), [
        'أداء جزئي',
        'معفاة',
        'لم يبدأ التتبع',
        'مسددة',
        'لا واجبات مسجلة',
      ]);
    },
  );
  test('invalid range is rejected', () {
    expect(
      () => ApartmentDuesReport(
        from: DateTime(2026, 4),
        to: DateTime(2026, 3),
        apartments: [],
        dues: ResidenceDuesOverview.empty,
      ),
      throwsArgumentError,
    );
  });
  for (final locale in ['ar', 'en']) {
    for (final scenario in ['normal', 'empty', 'many']) {
      test('PDF $locale $scenario', () async {
        final report = scenario == 'normal'
            ? sample()
            : ApartmentDuesReport(
                from: DateTime(2026, 1),
                to: DateTime(2026, 6, 30),
                apartments: scenario == 'empty'
                    ? []
                    : List.generate(90, (i) => apartment('${i + 1}')),
                dues: ResidenceDuesOverview.empty,
              );
        final bytes = await buildApartmentDuesReportPdf(
          report: report,
          residenceName: 'النخيل',
          residenceAddress: 'شارع الحسن الثاني',
          residenceCity: '6141010',
          localeName: locale,
          generatedAt: DateTime(2026, 9, 23),
        );
        final raw = String.fromCharCodes(bytes);
        expect(raw.startsWith('%PDF'), isTrue);
        final pages = RegExp(r'/Type\s*/Page\b').allMatches(raw).length;
        const dir = String.fromEnvironment('REPORT_PREVIEW_DIR');
        if (dir.isNotEmpty) {
          final file = File('$dir/apartment-dues-$locale-$scenario.pdf');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes);
        }
        expect(pages, scenario == 'many' ? greaterThan(1) : 1);
      });
    }
  }
}

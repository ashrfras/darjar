import 'dart:io';
import 'package:darjar/features/reports/domain/monthly_dues_report.dart';
import 'package:darjar/features/reports/presentation/monthly_dues_report_document.dart';
import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'apartment_dues_report_test.dart' show apartment, due, payment;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
  });
  MonthlyDuesReport sample({int count = 3, int year = 2026}) =>
      MonthlyDuesReport(
        year: year,
        asOf: DateTime(2026, 9, 23),
        apartments: [for (var i = 1; i <= count; i++) apartment('$i')],
        dues: ResidenceDuesOverview(
          dues: [
            due('old1', '1', '2025-11'),
            due('old2', '1', '2025-12'),
            due('jan', '1', '2026-01'),
            due('feb', '1', '2026-02'),
            due('mar', '1', '2026-03'),
            due('apr', '1', '2026-04', exempt: true),
            due('future', '1', '2026-10'),
            due('prepaid', '1', '2026-11'),
          ],
          payments: [
            payment('feb', 50, DateTime(2026, 9)),
            payment('mar', 200, DateTime(2026, 9)),
            payment('jan', 200, DateTime(2026, 10)),
            payment('prepaid', 200, DateTime(2026, 9)),
          ],
        ),
      );
  test('month states, current cutoff, prior debt and future prepayments', () {
    final report = sample();
    final row = report.rows.first;
    expect(row.months.map((c) => c.status), [
      MonthlyDuesStatus.unpaid,
      MonthlyDuesStatus.partial,
      MonthlyDuesStatus.paid,
      MonthlyDuesStatus.exempt,
      ...List.filled(5, MonthlyDuesStatus.notRecorded),
      MonthlyDuesStatus.future,
      MonthlyDuesStatus.paid,
      MonthlyDuesStatus.future,
    ]);
    expect(row.months[1].remaining, 150);
    expect(row.unpaidCount, 3);
    expect(row.partialCount, 1);
    expect(row.remaining, 750);
    expect(report.remaining, 750);
    expect(row.prior.length, 2);
    expect(report.rows[1].remaining, 0);
    expect(monthlyDuesPeriodList(row.prior, 'en'), 'November - December 2025');
    expect(monthlyDuesPeriodList(row.prior, 'ar'), 'نونبر إلى دجنبر 2025');
  });
  test('old year includes later payments and excludes later charges', () {
    final report = sample(year: 2025);
    expect(report.rows.first.unpaidCount, 2);
    expect(report.remaining, 400);
  });
  test(
    'opening paid month marks earlier months paid without adding income',
    () {
      final report = MonthlyDuesReport(
        year: 2026,
        asOf: DateTime(2026, 9, 23),
        apartments: [
          const ResidenceApartment(
            id: '1',
            number: '1',
            floorId: 'f',
            duesTrackingStartPeriodKey: '2026-05',
            openingPaidThroughPeriodKey: '2026-04',
          ),
        ],
        dues: ResidenceDuesOverview(
          dues: [
            for (var month = 5; month <= 9; month++)
              due('month-$month', '1', '2026-0$month'),
          ],
          payments: [],
        ),
      );
      final row = report.rows.single;
      expect(row.months.map((cell) => cell.status), [
        ...List.filled(4, MonthlyDuesStatus.paid),
        ...List.filled(5, MonthlyDuesStatus.unpaid),
        ...List.filled(3, MonthlyDuesStatus.future),
      ]);
      expect(row.unpaidCount, 5);
      expect(row.remaining, 1000);
      expect(row.months.take(4).every((cell) => cell.remaining == 0), isTrue);
    },
  );
  test(
    'tracking start distinguishes missing records from untracked months',
    () {
      final report = MonthlyDuesReport(
        year: 2026,
        asOf: DateTime(2026, 9),
        apartments: [
          const ResidenceApartment(
            id: 'a',
            number: '1',
            floorId: 'f',
            duesTrackingStartPeriodKey: '2026-03',
          ),
          apartment('2', active: false),
        ],
        dues: ResidenceDuesOverview.empty,
      );
      expect(report.rows.first.months[0].status, MonthlyDuesStatus.notStarted);
      expect(report.rows.first.months[2].status, MonthlyDuesStatus.notRecorded);
      expect(report.rows[1].months[0].status, MonthlyDuesStatus.notStarted);
      expect(report.remaining, 0);
    },
  );
  for (final locale in ['ar', 'en']) {
    for (final count in [0, 3, 80]) {
      test('PDF $locale apartments $count', () async {
        final bytes = await buildMonthlyDuesReportPdf(
          report: sample(count: count),
          residenceName: 'DarJar',
          residenceAddress: '',
          residenceCity: '',
          localeName: locale,
        );
        expect(String.fromCharCodes(bytes).startsWith('%PDF'), isTrue);
        final pages = RegExp(
          r'/Type\s*/Page\b',
        ).allMatches(String.fromCharCodes(bytes)).length;
        expect(
          pages,
          count == 0
              ? 1
              : count == 3
              ? 1
              : greaterThan(2),
        );
        const dir = String.fromEnvironment('REPORT_PREVIEW_DIR');
        if (dir.isNotEmpty) {
          final file = File('$dir/monthly-$locale-$count.pdf');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes);
        }
      });
    }
  }
}

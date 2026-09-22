import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/features/reports/data/financial_report_data.dart';
import 'package:darjar/features/reports/presentation/financial_report_page.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required String role,
    bool financial = false,
  }) async {
    final router = GoRouter(
      initialLocation: financial
          ? AppRoutes.financialReport
          : AppRoutes.reports,
      routes: [
        GoRoute(
          path: AppRoutes.reports,
          builder: (_, _) => const Scaffold(body: ResidenceReportsPage()),
        ),
        GoRoute(
          path: AppRoutes.financialReport,
          builder: (_, _) =>
              const Scaffold(body: ResidenceReportsPage(financial: true)),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          residenceContextProvider.overrideWith(
            (ref) async => ResidenceContext(
              residences: [
                UserResidence(
                  id: 'r',
                  name: 'إقامة النخيل',
                  address: '',
                  city: '',
                  role: role,
                  apartmentId: 'a',
                ),
              ],
              activeResidenceId: 'r',
            ),
          ),
          financialReportDataProvider.overrideWith(
            (ref) async => throw Exception('offline'),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('reports menu opens date range form', (tester) async {
    await pump(tester, role: 'owner');
    await tester.tap(find.byKey(const Key('financial-report-link')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('financial-report-date-range')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('download-financial-report')), findsNothing);
    await tester.tap(find.byKey(const Key('financial-report-date-range')));
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('direct report access is denied to ordinary resident', (
    tester,
  ) async {
    await pump(tester, role: 'resident', financial: true);
    expect(find.byKey(const Key('generate-financial-report')), findsNothing);
    expect(find.text('التقارير متاحة لإدارة الإقامة فقط.'), findsOneWidget);
  });
  testWidgets('failed load enables retry without exporting empty data', (
    tester,
  ) async {
    await pump(tester, role: 'owner', financial: true);
    await tester.tap(find.byKey(const Key('generate-financial-report')));
    await tester.pumpAndSettle();
    expect(find.text('تعذر إعداد التقرير. حاول مجددًا.'), findsOneWidget);
    expect(find.byKey(const Key('download-financial-report')), findsNothing);
    expect(find.text('معاينة التقرير'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

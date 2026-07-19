import 'package:darjar/app/app.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_theme.dart';
import 'package:darjar/core/responsive/window_size_class.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_chip.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('design foundation', () {
    test('uses the handoff breakpoints', () {
      expect(windowSizeClassFor(599), WindowSizeClass.compact);
      expect(windowSizeClassFor(600), WindowSizeClass.medium);
      expect(windowSizeClassFor(1023), WindowSizeClass.medium);
      expect(windowSizeClassFor(1024), WindowSizeClass.expanded);
    });

    test('uses the DarJar canvas and primary color', () {
      expect(AppTheme.light.scaffoldBackgroundColor, AppColors.canvas);
      expect(AppTheme.light.colorScheme.primary, AppColors.primary);
    });
  });

  testWidgets('compact shell starts in Arabic and uses bottom navigation', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));

    expect(find.byKey(const Key('compact-shell')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('دارجار'), findsOneWidget);
    expect(find.text('المجتمع'), findsWidgets);
    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.rtl,
    );
  });

  testWidgets('medium shell uses a navigation rail', (tester) async {
    await _pumpApp(tester, size: const Size(800, 900));

    expect(find.byKey(const Key('medium-shell')), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('expanded shell uses the full residence sidebar', (tester) async {
    await _pumpApp(tester, size: const Size(1280, 800));

    expect(find.byKey(const Key('expanded-shell')), findsOneWidget);
    expect(find.text('إقامة الياسمين'), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('primary navigation switches shell destinations', (tester) async {
    await _pumpApp(tester, size: const Size(390, 844));

    await tester.tap(find.text('السوق'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('section-marketplace')), findsOneWidget);
  });

  testWidgets('component gallery displays every reusable primitive', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(390, 844));

    await tester.tap(find.byKey(const Key('gallery-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('component-gallery')), findsOneWidget);
    expect(find.byType(DarJarButton), findsNWidgets(3));
    expect(find.byType(DarJarTextField), findsOneWidget);
    expect(find.byType(DarJarChip), findsNWidgets(2));
    expect(find.byType(DarJarBadge), findsNWidgets(3));
    expect(find.byType(DarJarCard), findsOneWidget);
  });

  testWidgets('English remains structurally supported with LTR layout', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      size: const Size(390, 844),
      locale: const Locale('en'),
    );

    expect(find.text('DarJar'), findsOneWidget);
    expect(find.text('Community'), findsWidgets);
    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.ltr,
    );
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required Size size,
  Locale locale = const Locale('ar'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(ProviderScope(child: DarJarApp(locale: locale)));
  await tester.pumpAndSettle();
}

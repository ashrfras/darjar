import 'package:darjar/app/app.dart';
import 'package:darjar/core/responsive/window_size_class.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('windowSizeClassFor', () {
    test('uses the handoff breakpoints', () {
      expect(windowSizeClassFor(599), WindowSizeClass.compact);
      expect(windowSizeClassFor(600), WindowSizeClass.medium);
      expect(windowSizeClassFor(1023), WindowSizeClass.medium);
      expect(windowSizeClassFor(1024), WindowSizeClass.expanded);
    });
  });

  testWidgets('starts in Arabic with right-to-left layout', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: DarJarApp()));
    await tester.pumpAndSettle();

    expect(find.text('دارجار'), findsOneWidget);
    expect(find.text('الأساس جاهز'), findsOneWidget);
    expect(find.text('حجم النافذة: صغير'), findsOneWidget);
    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.rtl,
    );
  });

  testWidgets('reports the expanded size class', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: DarJarApp()));
    await tester.pumpAndSettle();

    expect(find.text('حجم النافذة: واسع'), findsOneWidget);
  });

  testWidgets('supports the English localization structure', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DarJarApp(locale: Locale('en'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('DarJar'), findsOneWidget);
    expect(find.text('Foundation ready'), findsOneWidget);
    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.ltr,
    );
  });
}

import 'package:darjar/core/widgets/darjar_keyboard_dismiss_region.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps focus inside the input and dismisses it outside', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: DarJarKeyboardDismissRegion(
          child: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: focusNode),
                Container(
                  key: Key('outside-area'),
                  width: 100,
                  height: 100,
                  color: Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('outside-area')));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });
}

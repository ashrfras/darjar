import 'package:flutter/material.dart';

/// Dismisses the software keyboard when the user taps outside the focused
/// input, while leaving taps inside that input alone so text selection keeps
/// working normally.
class DarJarKeyboardDismissRegion extends StatelessWidget {
  const DarJarKeyboardDismissRegion({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final focus = FocusManager.instance.primaryFocus;
        final renderObject = focus?.context?.findRenderObject();

        if (renderObject is RenderBox && renderObject.attached) {
          final localPosition = renderObject.globalToLocal(event.position);
          if (renderObject.paintBounds.contains(localPosition)) return;
        }

        focus?.unfocus();
      },
      child: child,
    );
  }
}

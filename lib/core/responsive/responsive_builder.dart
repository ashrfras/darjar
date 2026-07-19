import 'package:darjar/core/responsive/window_size_class.dart';
import 'package:flutter/widgets.dart';

typedef ResponsiveWidgetBuilder =
    Widget Function(BuildContext context, WindowSizeClass sizeClass);

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({required this.builder, super.key});

  final ResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, windowSizeClassFor(constraints.maxWidth));
      },
    );
  }
}

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/core/responsive/responsive_builder.dart';
import 'package:darjar/core/responsive/window_size_class.dart';
import 'package:flutter/material.dart';

class FoundationPage extends StatelessWidget {
  const FoundationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: ResponsiveBuilder(
          builder: (context, sizeClass) {
            final maxWidth = switch (sizeClass) {
              WindowSizeClass.compact => 480.0,
              WindowSizeClass.medium => 720.0,
              WindowSizeClass.expanded => 840.0,
            };

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.apartment_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localizations.appName,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localizations.foundationTitle,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localizations.foundationDescription,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localizations.windowSizeLabel(
                          _localizedSize(localizations, sizeClass),
                        ),
                        key: const Key('window-size-label'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _localizedSize(
    AppLocalizations localizations,
    WindowSizeClass sizeClass,
  ) {
    return switch (sizeClass) {
      WindowSizeClass.compact => localizations.compactSize,
      WindowSizeClass.medium => localizations.mediumSize,
      WindowSizeClass.expanded => localizations.expandedSize,
    };
  }
}

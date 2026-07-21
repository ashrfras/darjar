import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DarJarPageHeader extends StatelessWidget {
  const DarJarPageHeader({
    required this.title,
    this.description,
    this.action,
    super.key,
  });

  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.xSmall),
          Text(description!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (action != null && constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              copy,
              const SizedBox(height: AppSpacing.large),
              Align(alignment: AlignmentDirectional.centerStart, child: action),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: copy),
            if (action != null) ...[
              const SizedBox(width: AppSpacing.large),
              action!,
            ],
          ],
        );
      },
    );
  }
}

class DarJarSubpageHeader extends StatelessWidget {
  const DarJarSubpageHeader({
    required this.title,
    required this.fallbackLocation,
    this.description,
    this.action,
    super.key,
  });

  final String title;
  final String fallbackLocation;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.filledTonal(
          key: const Key('subpage-back-button'),
          tooltip: AppLocalizations.of(context).back,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(fallbackLocation);
            }
          },
          icon: const BackButtonIcon(),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: DarJarPageHeader(
            title: title,
            description: description,
            action: action,
          ),
        ),
      ],
    );
  }
}

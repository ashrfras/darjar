import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_chip.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:flutter/material.dart';

class ComponentGalleryPage extends StatelessWidget {
  const ComponentGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      key: const Key('component-gallery'),
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarSubpageHeader(
                title: localizations.componentGallery,
                fallbackLocation: AppRoutes.community,
                description: localizations.componentGalleryDescription,
              ),
              const SizedBox(height: AppSpacing.xLarge),
              _GallerySection(
                title: localizations.buttons,
                child: Wrap(
                  spacing: AppSpacing.medium,
                  runSpacing: AppSpacing.medium,
                  children: [
                    DarJarButton(
                      label: localizations.primaryAction,
                      icon: Icons.add_rounded,
                      onPressed: () {},
                    ),
                    DarJarButton(
                      label: localizations.secondaryAction,
                      variant: DarJarButtonVariant.secondary,
                      onPressed: () {},
                    ),
                    DarJarButton(
                      label: localizations.disabledAction,
                      onPressed: null,
                    ),
                  ],
                ),
              ),
              _GallerySection(
                title: localizations.fields,
                child: DarJarTextField(
                  label: localizations.residenceName,
                  hint: localizations.residenceNameHint,
                  prefixIcon: Icons.apartment_rounded,
                ),
              ),
              _GallerySection(
                title: localizations.chipsAndBadges,
                child: Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    DarJarChip(label: localizations.all, selected: true),
                    DarJarChip(label: localizations.announcements),
                    DarJarBadge(label: localizations.newLabel),
                    DarJarBadge(
                      label: localizations.completedLabel,
                      tone: DarJarBadgeTone.success,
                    ),
                    DarJarBadge(
                      label: localizations.processingLabel,
                      tone: DarJarBadgeTone.warning,
                    ),
                  ],
                ),
              ),
              _GallerySection(
                title: localizations.cards,
                child: DarJarCard(
                  child: Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.campaign_outlined)),
                      const SizedBox(width: AppSpacing.large),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.sampleCardTitle,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xSmall),
                            Text(
                              localizations.sampleCardDescription,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GallerySection extends StatelessWidget {
  const _GallerySection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          child,
        ],
      ),
    );
  }
}

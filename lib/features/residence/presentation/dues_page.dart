import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/residence/data/residence_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DuesPage extends ConsumerWidget {
  const DuesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final records = ref.watch(duesRecordsProvider);

    return SingleChildScrollView(
      key: const Key('dues-page'),
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarSubpageHeader(
                title: localizations.duesStatus,
                fallbackLocation: AppRoutes.residence,
                description: localizations.duesPageDescription,
              ),
              const SizedBox(height: AppSpacing.xLarge),
              DarJarCard(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.warningSoft,
                      foregroundColor: AppColors.warning,
                      child: Icon(Icons.info_outline_rounded),
                    ),
                    const SizedBox(width: AppSpacing.large),
                    Expanded(
                      child: Text(
                        localizations.manualDuesNotice,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              for (final record in records) ...[
                DarJarCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.period,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xSmall),
                            Text(
                              record.amountLabel,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      DarJarBadge(
                        label: record.statusLabel,
                        tone: record.isPaid
                            ? DarJarBadgeTone.success
                            : DarJarBadgeTone.warning,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

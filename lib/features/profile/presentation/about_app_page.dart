import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_brand.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/profile/data/app_package_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AboutAppPage extends ConsumerWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final packageInfo = ref.watch(appPackageInfoProvider);

    return SingleChildScrollView(
      key: const Key('about-app-page'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xLarge,
        AppSpacing.small,
        AppSpacing.xLarge,
        AppSpacing.xLarge,
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarSubpageHeader(
                title: localizations.aboutApp,
                fallbackLocation: AppRoutes.profile,
              ),
              const SizedBox(height: AppSpacing.medium),
              DarJarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: DarJarBrand(logoSize: 44)),
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      localizations.aboutAppDescription,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xLarge),
                    DecoratedBox(
                      key: const Key('about-details-card'),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Column(
                        children: [
                          _AboutDetail(
                            label: localizations.appVersion,
                            value: packageInfo.when(
                              data: (info) => info.version,
                              loading: () => localizations.dataLoading,
                              error: (_, _) => localizations.notAvailable,
                            ),
                            valueKey: const Key('app-version-value'),
                          ),
                          const Divider(),
                          _AboutDetail(
                            label: localizations.appRevision,
                            value: packageInfo.when(
                              data: (info) => info.buildNumber,
                              loading: () => localizations.dataLoading,
                              error: (_, _) => localizations.notAvailable,
                            ),
                            valueKey: const Key('app-revision-value'),
                          ),
                          const Divider(),
                          _AboutDetail(
                            label: localizations.appPublisher,
                            value: 'Raqmain®',
                            valueKey: const Key('app-publisher-value'),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Text(
                      localizations.appCopyright,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutDetail extends StatelessWidget {
  const _AboutDetail({
    required this.label,
    required this.value,
    required this.valueKey,
    this.textDirection,
  });

  final String label;
  final String value;
  final Key valueKey;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: AppSpacing.medium),
          Text(
            value,
            key: valueKey,
            textDirection: textDirection,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_brand.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

const _supportEmail = 'support@raqmain.ma';

typedef LandingHeroBuilder = Widget Function(VoidCallback onLearnMore);

class WebLandingPage extends StatefulWidget {
  const WebLandingPage({
    required this.heroBuilder,
    required this.onStart,
    super.key,
  });

  final LandingHeroBuilder heroBuilder;
  final VoidCallback onStart;

  @override
  State<WebLandingPage> createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage> {
  final _firstSectionKey = GlobalKey();

  Future<void> _scrollToSections() async {
    final sectionContext = _firstSectionKey.currentContext;
    if (sectionContext == null) return;
    await Scrollable.ensureVisible(
      sectionContext,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      key: const Key('onboarding-page'),
      body: SafeArea(
        child: SelectionArea(
          child: SingleChildScrollView(
            key: const Key('web-landing-scroll-view'),
            child: Column(
              children: [
                _LandingHeader(onStart: widget.onStart),
                widget.heroBuilder(_scrollToSections),
                _LandingSections(
                  localizations: localizations,
                  onStart: widget.onStart,
                  firstSectionKey: _firstSectionKey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LandingHeader extends StatelessWidget {
  const _LandingHeader({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      key: const Key('web-landing-header'),
      height: 58,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xLarge),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Row(
            children: [
              const DarJarBrand(logoSize: 31, fontSize: 16),
              const Spacer(),
              DarJarButton(
                label: localizations.getStarted,
                onPressed: onStart,
                variant: DarJarButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandingSections extends StatelessWidget {
  const _LandingSections({
    required this.localizations,
    required this.onStart,
    required this.firstSectionKey,
  });

  final AppLocalizations localizations;
  final VoidCallback onStart;
  final GlobalKey firstSectionKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionShell(
          key: firstSectionKey,
          child: _FeatureSection(
            key: const Key('landing-darjar-section'),
            icon: Icons.apartment_rounded,
            title: localizations.landingDarjarTitle,
            description: localizations.landingDarjarDescription,
            preview: const _ResidenceOverviewPreview(),
          ),
        ),
        _SectionShell(
          backgroundColor: AppColors.surface,
          child: _FeatureSection(
            key: const Key('landing-finance-section'),
            icon: Icons.account_balance_wallet_outlined,
            title: localizations.landingFinanceTitle,
            description: localizations.landingFinanceDescription,
            preview: const _FinancePreview(),
            previewFirst: true,
          ),
        ),
        _SectionShell(
          child: _FeatureSection(
            key: const Key('landing-community-section'),
            icon: Icons.forum_outlined,
            title: localizations.landingCommunityTitle,
            description: localizations.landingCommunityDescription,
            preview: const _CommunityPreview(),
          ),
        ),
        _SectionShell(
          backgroundColor: AppColors.surface,
          child: _FeatureSection(
            key: const Key('landing-services-section'),
            icon: Icons.handyman_outlined,
            title: localizations.landingServicesTitle,
            description: localizations.landingServicesDescription,
            preview: const _ServicesPreview(),
            previewFirst: true,
          ),
        ),
        _SectionShell(
          child: _FeatureSection(
            key: const Key('landing-management-section'),
            icon: Icons.domain_outlined,
            title: localizations.landingManagementTitle,
            description: localizations.landingManagementDescription,
            preview: const _ManagementPreview(),
          ),
        ),
        _FinalCallToAction(localizations: localizations, onStart: onStart),
        _LandingFooter(localizations: localizations),
      ],
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.child, this.backgroundColor, super.key});

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xLarge,
        vertical: 72,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: child,
        ),
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.preview,
    this.previewFirst = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget preview;
  final bool previewFirst;

  @override
  Widget build(BuildContext context) {
    final copy = _FeatureCopy(
      icon: icon,
      title: title,
      description: description,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              copy,
              const SizedBox(height: AppSpacing.xxLarge),
              preview,
            ],
          );
        }

        final children = <Widget>[
          Expanded(child: copy),
          const SizedBox(width: 72),
          Expanded(child: preview),
        ];
        return Row(
          children: previewFirst ? children.reversed.toList() : children,
        );
      },
    );
  }
}

class _FeatureCopy extends StatelessWidget {
  const _FeatureCopy({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.large),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.medium),
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: IgnorePointer(
        key: const Key('landing-preview-non-interactive'),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primarySoft.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PreviewFrameHandle(),
              const SizedBox(height: AppSpacing.medium),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xLarge),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.outline),
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A17151D),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewFrameHandle extends StatelessWidget {
  const _PreviewFrameHandle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < 3; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.24),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

class _ResidenceOverviewPreview extends StatelessWidget {
  const _ResidenceOverviewPreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PreviewTitle(icon: Icons.home_outlined, label: 'إقامتي'),
          const SizedBox(height: AppSpacing.xLarge),
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: const Row(
              children: [
                Icon(Icons.apartment_rounded, color: AppColors.primary),
                SizedBox(width: AppSpacing.medium),
                Expanded(child: Text('إقامة الأمل · الدار البيضاء')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          const _PreviewRow(
            icon: Icons.campaign_outlined,
            label: 'آخر الأخبار',
          ),
          const _PreviewRow(
            icon: Icons.receipt_long_outlined,
            label: 'المالية والوثائق',
          ),
          const _PreviewRow(
            icon: Icons.people_outline,
            label: 'السكان والإدارة',
          ),
        ],
      ),
    );
  }
}

class _FinancePreview extends StatelessWidget {
  const _FinancePreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PreviewTitle(
            icon: Icons.account_balance_wallet_outlined,
            label: 'مالية الإقامة',
          ),
          const SizedBox(height: AppSpacing.xLarge),
          Text('الرصيد الحالي', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            '18,450 د.م.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.large),
          const Row(
            children: [
              Expanded(
                child: _FinanceStat(
                  label: 'المداخيل',
                  value: '24,300',
                  positive: true,
                ),
              ),
              SizedBox(width: AppSpacing.medium),
              Expanded(
                child: _FinanceStat(label: 'المصاريف', value: '5,850'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          const Divider(),
          const SizedBox(height: AppSpacing.medium),
          const _TransactionRow(label: 'صيانة المصعد', value: '− 1,200 د.م.'),
          const _TransactionRow(
            label: 'اشتراكات يوليوز',
            value: '+ 3,600 د.م.',
          ),
        ],
      ),
    );
  }
}

class _FinanceStat extends StatelessWidget {
  const _FinanceStat({
    required this.label,
    required this.value,
    this.positive = false,
  });

  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: positive ? AppColors.primarySoft : AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xSmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            size: 20,
            color: AppColors.inkMuted,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _CommunityPreview extends StatelessWidget {
  const _CommunityPreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PreviewTitle(icon: Icons.forum_outlined, label: 'المجتمع'),
          const SizedBox(height: AppSpacing.xLarge),
          const _PostPreview(
            initials: 'س',
            name: 'سلمى المريني',
            text: 'تم تحديد موعد صيانة المصعد يوم السبت صباحاً.',
          ),
          const SizedBox(height: AppSpacing.medium),
          const Divider(),
          const SizedBox(height: AppSpacing.medium),
          const _PostPreview(
            initials: 'م',
            name: 'محمد العلوي',
            text: 'شكراً للجيران المشاركين في لقاء الإقامة.',
          ),
        ],
      ),
    );
  }
}

class _PostPreview extends StatelessWidget {
  const _PostPreview({
    required this.initials,
    required this.name,
    required this.text,
  });

  final String initials;
  final String name;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          foregroundColor: AppColors.primary,
          child: Text(initials),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xSmall),
              Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServicesPreview extends StatelessWidget {
  const _ServicesPreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PreviewTitle(icon: Icons.handyman_outlined, label: 'الخدمات'),
          const SizedBox(height: AppSpacing.xLarge),
          const _ServiceRow(
            icon: Icons.plumbing_outlined,
            title: 'سباكة',
            subtitle: 'خدمات موصى بها محلياً',
          ),
          const SizedBox(height: AppSpacing.medium),
          const _ServiceRow(
            icon: Icons.elevator_outlined,
            title: 'صيانة المصاعد',
            subtitle: 'مقدمو خدمات قريبون',
          ),
          const SizedBox(height: AppSpacing.medium),
          const _ServiceRow(
            icon: Icons.park_outlined,
            title: 'البستنة',
            subtitle: 'تجارب يشاركها المجتمع',
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManagementPreview extends StatelessWidget {
  const _ManagementPreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PreviewTitle(
            icon: Icons.domain_outlined,
            label: 'إدارة الإقامة',
          ),
          const SizedBox(height: AppSpacing.xLarge),
          const Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.medium,
            children: [
              _ManagementStat(value: '48', label: 'شقة'),
              _ManagementStat(value: '37', label: 'ساكناً'),
              _ManagementStat(value: '31', label: 'اشتراكاً مؤدى'),
            ],
          ),
          const SizedBox(height: AppSpacing.xLarge),
          const _PreviewRow(
            icon: Icons.meeting_room_outlined,
            label: 'الشقق والسكان',
          ),
          const _PreviewRow(icon: Icons.payments_outlined, label: 'الاشتراكات'),
          const _PreviewRow(
            icon: Icons.settings_outlined,
            label: 'بيانات الإقامة',
          ),
        ],
      ),
    );
  }
}

class _ManagementStat extends StatelessWidget {
  const _ManagementStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _PreviewTitle extends StatelessWidget {
  const _PreviewTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.small),
        Text(label, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        children: [
          Icon(icon, color: AppColors.inkMuted, size: 21),
          const SizedBox(width: AppSpacing.medium),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _FinalCallToAction extends StatelessWidget {
  const _FinalCallToAction({
    required this.localizations,
    required this.onStart,
  });

  final AppLocalizations localizations;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('landing-final-cta'),
      width: double.infinity,
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xLarge,
        vertical: 72,
      ),
      child: Column(
        children: [
          Text(
            localizations.landingCtaTitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            localizations.landingCtaDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.xLarge),
          FilledButton.icon(
            key: const Key('landing-final-start-button'),
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(localizations.getStarted),
          ),
        ],
      ),
    );
  }
}

class _LandingFooter extends StatelessWidget {
  const _LandingFooter({required this.localizations});

  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('landing-footer'),
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xLarge,
            runSpacing: AppSpacing.large,
            children: [
              const DarJarBrand(),
              Wrap(
                spacing: AppSpacing.small,
                children: [
                  TextButton(
                    onPressed: () => context.go(AppRoutes.publicPrivacyPolicy),
                    child: Text(localizations.privacyPolicy),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.deleteAccount),
                    child: Text(localizations.deleteAccountTitle),
                  ),
                  TextButton(
                    onPressed: () =>
                        launchUrl(Uri(scheme: 'mailto', path: _supportEmail)),
                    child: Text(localizations.landingSupport),
                  ),
                ],
              ),
              Text(
                localizations.appCopyright,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

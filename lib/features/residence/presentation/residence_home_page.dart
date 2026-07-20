import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/residence/data/residence_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ResidenceHomePage extends ConsumerWidget {
  const ResidenceHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;

    if (compact) {
      return _CompactResidenceHome(
        requests: ref.watch(maintenanceRequestsProvider),
      );
    }

    final residenceAreas = [
      (
        title: localizations.maintenanceRequests,
        description: localizations.maintenanceDescription,
        icon: Icons.handyman_outlined,
        color: AppColors.warning,
        route: AppRoutes.maintenance,
      ),
      (
        title: localizations.duesStatus,
        description: localizations.duesDescription,
        icon: Icons.receipt_long_outlined,
        color: AppColors.directory,
        route: AppRoutes.dues,
      ),
      (
        title: localizations.managementInformation,
        description: localizations.managementDescription,
        icon: Icons.business_outlined,
        color: AppColors.residence,
        route: AppRoutes.management,
      ),
      (
        title: localizations.documents,
        description: localizations.documentsDescription,
        icon: Icons.folder_outlined,
        color: AppColors.community,
        route: '',
      ),
    ];

    return SingleChildScrollView(
      key: const Key('residence-home-page'),
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarPageHeader(
                title: localizations.residence,
                description: localizations.residencePageDescription,
              ),
              const SizedBox(height: AppSpacing.xLarge),
              Wrap(
                spacing: AppSpacing.large,
                runSpacing: AppSpacing.large,
                children: [
                  for (final service in residenceAreas)
                    SizedBox(
                      width: 440,
                      child: DarJarCard(
                        onTap: service.route.isEmpty
                            ? null
                            : () => context.go(service.route),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: service.color.withValues(
                                alpha: 0.10,
                              ),
                              foregroundColor: service.color,
                              child: Icon(service.icon),
                            ),
                            const SizedBox(width: AppSpacing.large),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    service.description,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactResidenceHome extends StatelessWidget {
  const _CompactResidenceHome({required this.requests});

  final List<MaintenanceRequest> requests;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final actions = [
      (localizations.duesStatus, Icons.credit_card_outlined, AppRoutes.dues),
      ('طلب صيانة', Icons.handyman_outlined, AppRoutes.maintenance),
      (
        localizations.managementInformation,
        Icons.business_outlined,
        AppRoutes.management,
      ),
      (localizations.documents, Icons.copy_all_outlined, ''),
    ];

    return SingleChildScrollView(
      key: const Key('residence-home-page'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('اختصارات سريعة', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0) const SizedBox(width: 7),
                Expanded(
                  child: _QuickAction(
                    label: actions[index].$1,
                    icon: actions[index].$2,
                    onTap: actions[index].$3.isEmpty
                        ? null
                        : () => context.go(actions[index].$3),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          const _DuesSummary(),
          const SizedBox(height: 18),
          _SectionHeading(
            title: localizations.maintenanceRequests,
            onTap: () => context.go(AppRoutes.maintenance),
          ),
          const SizedBox(height: 8),
          _MaintenanceSummary(requests: requests),
          const SizedBox(height: 18),
          const _SectionHeading(title: 'حجوزات المرافق'),
          const SizedBox(height: 8),
          const _FacilityBooking(),
          const SizedBox(height: 18),
          const _SectionHeading(title: 'إعلانات الإدارة'),
          const SizedBox(height: 8),
          const _ManagementNotice(),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.outline),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 88,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.directory, size: 25),
                const SizedBox(height: 8),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DuesSummary extends StatelessWidget {
  const _DuesSummary();

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.go(AppRoutes.dues),
      child: Row(
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 104,
                  height: 104,
                  child: CircularProgressIndicator(
                    value: .72,
                    strokeWidth: 7,
                    backgroundColor: AppColors.outline,
                    color: AppColors.directory,
                  ),
                ),
                Text(
                  'مدفوع\nحتى شهر\nيوليو 2026',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.directory),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة الحساب',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const DarJarBadge(
                  label: 'لا توجد متأخرات',
                  tone: DarJarBadgeTone.success,
                ),
                const SizedBox(height: 10),
                Text(
                  'المبلغ المستحق',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  '450.00 درهم',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'عرض التفاصيل  ‹',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.directory),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ),
        DarJarButton(
          label: 'عرض الكل',
          onPressed: onTap,
          variant: DarJarButtonVariant.tertiary,
        ),
      ],
    );
  }
}

class _MaintenanceSummary extends StatelessWidget {
  const _MaintenanceSummary({required this.requests});

  final List<MaintenanceRequest> requests;

  @override
  Widget build(BuildContext context) {
    final visible = requests.take(3).toList();
    return DarJarCard(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      onTap: () => context.go(AppRoutes.maintenance),
      child: Column(
        children: [
          for (var index = 0; index < visible.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.residenceSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      index == 0
                          ? Icons.elevator_outlined
                          : Icons.lightbulb_outline,
                      color: AppColors.residence,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visible[index].title,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          visible[index].location,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  DarJarBadge(
                    label: visible[index].status == MaintenanceStatus.completed
                        ? 'مكتمل'
                        : 'قيد المعالجة',
                    tone: visible[index].status == MaintenanceStatus.completed
                        ? DarJarBadgeTone.success
                        : DarJarBadgeTone.warning,
                  ),
                ],
              ),
            ),
            if (index != visible.length - 1) const Divider(),
          ],
          DarJarButton(
            onPressed: () => context.go(AppRoutes.createMaintenance),
            icon: Icons.add_circle_outline_rounded,
            label: 'طلب صيانة جديد',
            variant: DarJarButtonVariant.tertiary,
          ),
        ],
      ),
    );
  }
}

class _FacilityBooking extends StatelessWidget {
  const _FacilityBooking();

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.directorySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.meeting_room_outlined,
              color: AppColors.directory,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قاعة الاجتماعات',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  'السبت 21 يونيو · 16:00–18:00',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          const DarJarBadge(label: 'مؤكدة', tone: DarJarBadgeTone.success),
        ],
      ),
    );
  }
}

class _ManagementNotice extends StatelessWidget {
  const _ManagementNotice();

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.directory,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تنظيف الخزانات',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'الثلاثاء 24 يونيو، من 09:00 إلى 13:00',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

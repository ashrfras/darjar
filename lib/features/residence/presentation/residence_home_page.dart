import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
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
    final dashboard = ref.watch(residenceDashboardProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      key: const Key('residence-home-page'),
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : AppSpacing.xLarge,
        compact ? 12 : AppSpacing.xLarge,
        compact ? 12 : AppSpacing.xLarge,
        compact ? 28 : AppSpacing.xxxLarge,
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!compact) ...[
                DarJarPageHeader(
                  title: AppLocalizations.of(context).residence,
                  description: AppLocalizations.of(
                    context,
                  ).residencePageDescription,
                ),
                const SizedBox(height: AppSpacing.xLarge),
              ],
              _DashboardGrid(data: dashboard),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({required this.data});

  final ResidenceDashboardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final pairWidth = wide
            ? (constraints.maxWidth - AppSpacing.large) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: AppSpacing.large,
          runSpacing: AppSpacing.medium,
          children: [
            SizedBox(width: constraints.maxWidth, child: _FinancialCard(data)),
            SizedBox(width: pairWidth, child: _MaintenanceCard(data)),
            SizedBox(
              width: pairWidth,
              child: _ExpenseCard(data.extraordinaryExpense),
            ),
            SizedBox(width: pairWidth, child: _DocumentsCard(data.documents)),
            SizedBox(
              width: pairWidth,
              child: _NotificationsCard(data.notifications),
            ),
            SizedBox(
              width: constraints.maxWidth,
              child: _ResidenceInfoCard(data),
            ),
          ],
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.child,
    required this.footerLabel,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Widget child;
  final String footerLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                _SectionIcon(
                  icon: icon,
                  color: iconColor,
                  background: iconBackground,
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: child,
          ),
          const SizedBox(height: 10),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 11),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    footerLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.inkMuted,
                  size: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  const _FinancialCard(this.data);

  final ResidenceDashboardData data;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return _DashboardCard(
      title: 'المالية',
      icon: Icons.account_balance_wallet_outlined,
      iconColor: AppColors.residence,
      iconBackground: AppColors.residenceSoft,
      footerLabel: localizations.duesStatus,
      onTap: () => context.go(AppRoutes.dues),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 300;
          final items = [
            _FinancialMetric(
              label: 'حالة الاشتراك',
              value: 'مدفوع',
              detail: 'شهر ${data.paidThrough}\nلا يوجد أي متأخرات',
              status: true,
            ),
            _FinancialMetric(
              label: 'المبلغ الشهري',
              value: '${data.monthlyDue}',
              suffix: 'درهم',
              detail: 'السداد قبل 05 يونيو',
            ),
            _FinancialMetric(
              label: 'آخر عملية دفع',
              value: '${data.lastPayment}',
              suffix: 'درهم',
              detail: 'بتاريخ ${data.lastPaymentDate}',
              receipt: true,
            ),
          ];
          if (narrow) {
            return Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  items[i],
                  if (i != items.length - 1) const Divider(),
                ],
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  Expanded(child: items[i]),
                  if (i != items.length - 1) const VerticalDivider(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FinancialMetric extends StatelessWidget {
  const _FinancialMetric({
    required this.label,
    required this.value,
    required this.detail,
    this.suffix,
    this.status = false,
    this.receipt = false,
  });

  final String label;
  final String value;
  final String detail;
  final String? suffix;
  final bool status;
  final bool receipt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 7),
          if (status)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.residenceSoft,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.residence,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.residence,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text.rich(
              TextSpan(
                text: value,
                children: [
                  if (suffix != null)
                    TextSpan(
                      text: ' $suffix',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: receipt
                            ? AppColors.residence
                            : AppColors.inkMuted,
                      ),
                    ),
                ],
              ),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: receipt ? AppColors.residence : AppColors.ink,
              ),
            ),
          const SizedBox(height: 7),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (receipt) ...[
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    color: AppColors.residence,
                    size: 17,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'عرض الإيصال',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.residence,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MaintenanceCard extends StatelessWidget {
  const _MaintenanceCard(this.data);

  final ResidenceDashboardData data;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return _DashboardCard(
      title: localizations.maintenanceRequests,
      icon: Icons.build_outlined,
      iconColor: const Color(0xFF367DDB),
      iconBackground: const Color(0xFFEAF2FF),
      footerLabel: 'عرض كل الطلبات',
      onTap: () => context.go(AppRoutes.maintenance),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _CountMetric(
                value: data.maintenanceCompleted,
                label: 'منجزة',
                color: AppColors.residence,
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: _CountMetric(
                value: data.maintenanceProcessing,
                label: 'قيد المعالجة',
                color: AppColors.warning,
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: _CountMetric(
                value: data.maintenanceOpen,
                label: 'طلبات مفتوحة',
                color: const Color(0xFF367DDB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountMetric extends StatelessWidget {
  const _CountMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Column(
        children: [
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard(this.expense);

  final ExtraordinaryExpense expense;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'المصاريف الاستثنائية',
      icon: Icons.pie_chart_outline_rounded,
      iconColor: const Color(0xFF7657D6),
      iconBackground: const Color(0xFFF0ECFF),
      footerLabel: 'عرض كل المصاريف الاستثنائية',
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: Image.asset(
              expense.imagePath,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  expense.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 9),
                Text(
                  '${(expense.progress * 100).round()}% مكتمل',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 5),
                LinearProgressIndicator(
                  value: expense.progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  backgroundColor: AppColors.outline,
                  color: AppColors.residence,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsetsDirectional.only(start: 12),
            decoration: const BoxDecoration(
              border: BorderDirectional(
                start: BorderSide(color: AppColors.outline),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المبلغ الإجمالي',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  '${expense.totalAmount} درهم',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'نصيب شقتك',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  '${expense.residentShare} درهم',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.residence),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard(this.documents);

  final List<ResidenceDocument> documents;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: AppLocalizations.of(context).documents,
      icon: Icons.folder_outlined,
      iconColor: AppColors.residence,
      iconBackground: AppColors.residenceSoft,
      footerLabel: 'عرض كل الوثائق',
      child: Column(
        children: [
          for (final document in documents)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppColors.danger,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Text(
                          'PDF · ${document.size}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard(this.notifications);

  final List<AdministrativeNotification> notifications;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'الإشعارات الإدارية',
      icon: Icons.notifications_none_rounded,
      iconColor: AppColors.warning,
      iconBackground: AppColors.warningSoft,
      footerLabel: 'عرض كل الإشعارات',
      child: Column(
        children: [
          for (final notification in notifications)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  const SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    notification.age,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ResidenceInfoCard extends StatelessWidget {
  const _ResidenceInfoCard(this.data);

  final ResidenceDashboardData data;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: AppLocalizations.of(context).managementInformation,
      icon: Icons.apartment_outlined,
      iconColor: AppColors.inkMuted,
      iconBackground: const Color(0xFFF1F2F4),
      footerLabel: 'عرض التفاصيل',
      onTap: () => context.go(AppRoutes.management),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _InfoMetric(
                label: 'عدد العمارات',
                value: '${data.buildingCount}',
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: _InfoMetric(
                label: 'عدد الشقق',
                value: '${data.unitCount}',
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: _InfoMetric(
                label: 'سنة البناء',
                value: '${data.constructionYear}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/utils/darjar_date_format.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_image_avatar.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:darjar/features/documents/presentation/residence_document_widgets.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:darjar/features/residence/data/residence_finance_repository.dart';
import 'package:darjar/features/residence/domain/finance_amount.dart';
import 'package:darjar/features/residence/data/residence_important_notifications.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:darjar/features/residence/data/residence_repository.dart';
import 'package:darjar/features/residence/data/residence_settings_repository.dart';
import 'package:darjar/features/residence/data/residence_setup_repository.dart';
import 'package:darjar/features/residence/presentation/moroccan_cities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ResidenceHomePage extends ConsumerWidget {
  const ResidenceHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(residenceDashboardProvider);
    final documents = ref.watch(residenceDocumentsProvider);
    final residentDues = ref.watch(residentDuesProvider);
    final finances = ref.watch(residenceFinancesProvider);
    final residenceMembers = ref.watch(residenceDirectoryProvider);
    final residenceSettings = ref.watch(residenceSettingsProvider);
    final activeResidence = ref.watch(
      residenceContextProvider.select(
        (context) => context.value?.activeResidence,
      ),
    );
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
                  title: activeResidence == null
                      ? AppLocalizations.of(context).residence
                      : AppLocalizations.of(context).residenceDisplayName(
                          normalizeResidenceName(activeResidence.name),
                        ),
                  description: activeResidence == null
                      ? AppLocalizations.of(context).residencePageDescription
                      : [
                          activeResidence.address,
                          localizedMoroccanCityName(
                            AppLocalizations.of(context),
                            activeResidence.city,
                          ),
                        ].where((value) => value.isNotEmpty).join(' • '),
                ),
                const SizedBox(height: AppSpacing.xLarge),
              ],
              if (compact && activeResidence != null) ...[
                DarJarCard(
                  key: const Key('residence-directory-card'),
                  onTap: () => context.push(AppRoutes.residenceResidents),
                  child: Row(
                    children: [
                      DarJarResidenceAvatar(
                        residenceId: activeResidence.id,
                        hasImage: activeResidence.hasImage,
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).residenceDisplayName(
                                normalizeResidenceName(activeResidence.name),
                              ),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (activeResidence.address.isNotEmpty ||
                                activeResidence.city.isNotEmpty)
                              Text(
                                [
                                      activeResidence.address,
                                      localizedMoroccanCityName(
                                        AppLocalizations.of(context),
                                        activeResidence.city,
                                      ),
                                    ]
                                    .where((value) => value.isNotEmpty)
                                    .join(' • '),
                                key: const Key(
                                  'compact-residence-address-and-city',
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.inkMuted,
                        size: 15,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
              if (activeResidence?.apartmentId.isEmpty ?? false) ...[
                const _ApartmentAssignmentAlert(),
                const SizedBox(height: AppSpacing.medium),
              ],
              _DashboardGrid(
                data: dashboard,
                documents: documents,
                residentDues: residentDues,
                finances: finances,
                residenceMembers: residenceMembers,
                residenceSettings: residenceSettings,
                joinedAt: activeResidence?.joinedAt,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApartmentAssignmentAlert extends StatelessWidget {
  const _ApartmentAssignmentAlert();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      key: const Key('apartment-not-assigned-alert'),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          const Icon(Icons.home_work_outlined, color: AppColors.warning),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Text(
              localizations.duesNoApartment,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({
    required this.data,
    required this.documents,
    required this.residentDues,
    required this.finances,
    required this.residenceMembers,
    required this.residenceSettings,
    required this.joinedAt,
  });

  final ResidenceDashboardData data;
  final AsyncValue<List<ResidenceDocument>> documents;
  final AsyncValue<ResidenceDuesOverview> residentDues;
  final AsyncValue<ResidenceFinances> finances;
  final AsyncValue<ResidenceMembersData> residenceMembers;
  final AsyncValue<ResidenceSettings> residenceSettings;
  final DateTime? joinedAt;

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
            SizedBox(
              width: constraints.maxWidth,
              child: _AccountCard(residentDues),
            ),
            SizedBox(
              width: constraints.maxWidth,
              child: _ResidenceFinancesCard(finances),
            ),
            SizedBox(width: pairWidth, child: _DocumentsCard(documents)),
            SizedBox(
              width: pairWidth,
              child: _NotificationsCard(dues: residentDues, joinedAt: joinedAt),
            ),
            SizedBox(
              width: constraints.maxWidth,
              child: _ResidenceInfoCard(
                members: residenceMembers.value,
                settings: residenceSettings.value,
              ),
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
    this.footerLabel,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Widget child;
  final String? footerLabel;
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
          if (footerLabel case final footerLabel?) ...[
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
          ] else
            const SizedBox(height: 10),
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

class _AccountCard extends StatelessWidget {
  const _AccountCard(this.duesState);

  final AsyncValue<ResidenceDuesOverview> duesState;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final overview = duesState.value;
    final currentPeriodKey = residenceDuesPeriodKey(DateTime.now());
    final due = overview?.duesForPeriod(currentPeriodKey).firstOrNull;
    final remainingThroughCurrentPeriod = overview?.debitThroughPeriod(
      currentPeriodKey,
    );
    final paymentGroup = overview?.paymentGroups.firstOrNull;
    final status = switch (due?.status) {
      ResidenceDueStatus.unpaid => localizations.duesStatusUnpaid,
      ResidenceDueStatus.partial => localizations.duesStatusPartial,
      ResidenceDueStatus.paid => localizations.duesStatusPaid,
      null => '—',
    };
    return _DashboardCard(
      title: localizations.myAccount,
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
              key: const Key('account-dues-status'),
              label: 'حالة الاشتراك',
              value: status,
              detail: due == null
                  ? localizations.duesNoRecords
                  : '${localizations.duesRemaining}: '
                        '$remainingThroughCurrentPeriod '
                        '${localizations.currency}',
              status: due?.status == ResidenceDueStatus.paid,
            ),
            _FinancialMetric(
              label: 'المبلغ الشهري',
              value: due == null ? '—' : '${due.amountDue}',
              suffix: 'درهم',
              detail: due == null
                  ? localizations.duesNoRecords
                  : localizations.duesPeriod(
                      _duesPeriodLabel(context, due.periodKey),
                    ),
            ),
            _FinancialMetric(
              key: const Key('account-last-payment-total'),
              label: 'آخر عملية دفع',
              value: paymentGroup == null ? '—' : '${paymentGroup.totalAmount}',
              suffix: 'درهم',
              detail: paymentGroup == null
                  ? localizations.duesNoPayments
                  : localizations.duesRecordedOn(
                      DarJarDateFormat.yMMMd(
                        paymentGroup.paidAt,
                        localizations.localeName,
                      ),
                    ),
              receipt: paymentGroup != null,
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
    super.key,
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

class _ResidenceFinancesCard extends StatelessWidget {
  const _ResidenceFinancesCard(this.finances);

  final AsyncValue<ResidenceFinances> finances;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final data = finances.value;
    return _DashboardCard(
      title: localizations.residenceFinances,
      icon: Icons.account_balance_outlined,
      iconColor: const Color(0xFF7657D6),
      iconBackground: const Color(0xFFF0ECFF),
      footerLabel: localizations.viewFinanceDetails,
      onTap: () => context.go(AppRoutes.residenceFinances),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final items = [
            _FinanceOverviewMetric(
              label: localizations.totalIncome,
              value: data == null
                  ? '—'
                  : '${_formatAmount(context, data.totalIncome)} ${localizations.currency}',
              color: AppColors.residence,
              icon: Icons.south_west_rounded,
            ),
            _FinanceOverviewMetric(
              label: localizations.totalExpenses,
              value: data == null
                  ? '—'
                  : '${_formatAmount(context, data.totalExpenses)} ${localizations.currency}',
              color: AppColors.warning,
              icon: Icons.north_east_rounded,
            ),
            _FinanceOverviewMetric(
              label: localizations.currentBalance,
              value: data == null
                  ? '—'
                  : '${_formatAmount(context, data.currentBalance)} ${localizations.currency}',
              color: const Color(0xFF7657D6),
              icon: Icons.account_balance_wallet_outlined,
            ),
            _FinanceOverviewMetric(
              label: localizations.collectionRate,
              value: data == null
                  ? '—'
                  : _formatPercentage(data.collectionRate),
              color: const Color(0xFF367DDB),
              icon: Icons.donut_large_rounded,
            ),
          ];
          final columns = constraints.maxWidth < 700 ? 2 : 4;
          final itemWidth =
              (constraints.maxWidth - AppSpacing.small * (columns - 1)) /
              columns;
          return Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              for (final item in items) SizedBox(width: itemWidth, child: item),
            ],
          );
        },
      ),
    );
  }
}

class _FinanceOverviewMetric extends StatelessWidget {
  const _FinanceOverviewMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard(this.documents);

  final AsyncValue<List<ResidenceDocument>> documents;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: AppLocalizations.of(context).documents,
      icon: Icons.folder_outlined,
      iconColor: AppColors.residence,
      iconBackground: AppColors.residenceSoft,
      footerLabel: AppLocalizations.of(context).viewAllDocuments,
      onTap: () => context.go(AppRoutes.documents),
      child: documents.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.large),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
          child: Text(
            AppLocalizations.of(context).documentsLoadError,
            textAlign: TextAlign.center,
          ),
        ),
        data: (items) {
          final visibleDocuments = items.take(3).toList(growable: false);
          if (visibleDocuments.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
              child: Text(
                AppLocalizations.of(context).noDocuments,
                textAlign: TextAlign.center,
              ),
            );
          }
          return Column(
            children: [
              for (final document in visibleDocuments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 32,
                        decoration: BoxDecoration(
                          color: document.isPdf
                              ? const Color(0xFFFFF0EE)
                              : AppColors.residenceSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          document.isPdf
                              ? Icons.picture_as_pdf_outlined
                              : Icons.image_outlined,
                          color: document.isPdf
                              ? AppColors.danger
                              : AppColors.residence,
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
                              '${residenceDocumentTypeLabel(AppLocalizations.of(context), document)}'
                              ' · ${residenceDocumentSizeLabel(document.sizeBytes)}',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({required this.dues, required this.joinedAt});

  final AsyncValue<ResidenceDuesOverview> dues;
  final DateTime? joinedAt;

  @override
  Widget build(BuildContext context) {
    final notifications = deriveImportantResidenceNotifications(
      duesOverview: dues.value ?? ResidenceDuesOverview.empty,
      joinedAt: joinedAt,
    );
    return _DashboardCard(
      title: AppLocalizations.of(context).importantNotifications,
      icon: Icons.notifications_none_rounded,
      iconColor: AppColors.warning,
      iconBackground: AppColors.warningSoft,
      child: Column(
        children: [
          for (final notification in notifications)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _notificationColor(notification.kind),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _notificationText(context, notification),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  if (notification.occurredAt case final occurredAt?) ...[
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.yMd(
                        AppLocalizations.of(context).localeName,
                      ).format(occurredAt),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _notificationText(
  BuildContext context,
  ImportantResidenceNotification notification,
) {
  final localizations = AppLocalizations.of(context);
  return switch (notification.kind) {
    ImportantResidenceNotificationKind.paymentRecorded =>
      localizations.duesMarkedPaidNotification(
        _duesPeriodLabel(context, notification.periodKey!),
      ),
    ImportantResidenceNotificationKind.overdueDues =>
      localizations.overdueDuesNotification(
        _duesPeriodLabel(context, notification.periodKey!),
      ),
    ImportantResidenceNotificationKind.membershipApproved =>
      localizations.membershipApprovedNotification,
  };
}

Color _notificationColor(ImportantResidenceNotificationKind kind) {
  return switch (kind) {
    ImportantResidenceNotificationKind.paymentRecorded => AppColors.primary,
    ImportantResidenceNotificationKind.overdueDues => AppColors.warning,
    ImportantResidenceNotificationKind.membershipApproved => AppColors.primary,
  };
}

class _ResidenceInfoCard extends StatelessWidget {
  const _ResidenceInfoCard({required this.members, required this.settings});

  final ResidenceMembersData? members;
  final ResidenceSettings? settings;

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
                key: const Key('residence-building-count'),
                label: AppLocalizations.of(context).residenceBuildingCount,
                value: settings == null ? '—' : '${settings!.buildings.length}',
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: _InfoMetric(
                key: const Key('residence-apartment-count'),
                label: AppLocalizations.of(context).residenceApartmentCount,
                value: members == null ? '—' : '${members!.apartments.length}',
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: _InfoMetric(
                key: const Key('residence-construction-year'),
                label: AppLocalizations.of(context).residenceConstructionYear,
                value: settings == null
                    ? '—'
                    : '${settings!.establishmentYear}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({required this.label, required this.value, super.key});

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

String _formatAmount(BuildContext context, num amount) {
  return formatFinanceAmount(
    amount,
    Localizations.localeOf(context).languageCode,
  );
}

String _formatPercentage(double value) {
  return '${(value * 100).round()}%';
}

String _duesPeriodLabel(BuildContext context, String periodKey) {
  final parts = periodKey.split('-');
  return DarJarDateFormat.yMMMM(
    DateTime(int.parse(parts[0]), int.parse(parts[1])),
    AppLocalizations.of(context).localeName,
  );
}

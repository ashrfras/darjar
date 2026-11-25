import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/utils/darjar_date_format.dart';
import 'package:darjar/core/utils/phone_number.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/activity_log/data/activity_log_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ActivityLogPage extends ConsumerWidget {
  const ActivityLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final uid = ref.watch(activityLogUserIdProvider);
    final access = ref.watch(developerAccessProvider);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xLarge,
            AppSpacing.small,
            AppSpacing.xLarge,
            AppSpacing.large,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarSubpageHeader(
                title: strings.appActivityLog,
                fallbackLocation: AppRoutes.profile,
              ),
              const SizedBox(height: AppSpacing.medium),
              Expanded(
                child: access.when(
                  skipLoadingOnRefresh: false,
                  data: (allowed) => allowed && uid != null
                      ? _ActivityTimeline(key: ValueKey(uid), uid: uid)
                      : Center(child: Text(strings.appActivityDenied)),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => _LoadError(
                    onRetry: () => ref.invalidate(developerAccessProvider),
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

class _ActivityTimeline extends ConsumerStatefulWidget {
  const _ActivityTimeline({required this.uid, super.key});

  final String uid;

  @override
  ConsumerState<_ActivityTimeline> createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends ConsumerState<_ActivityTimeline> {
  final _events = <ActivityEvent>[];
  final _ids = <String>{};
  String? _cursor;
  var _loading = true;
  bool? _failedRefresh;
  bool _openingResidence = false;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage({bool refresh = false}) async {
    final repository = ref.read(activityLogRepositoryProvider);
    try {
      final page = await repository.fetchPage(
        widget.uid,
        cursor: refresh ? null : _cursor,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _events.clear();
          _ids.clear();
        }
        _events.addAll(page.events.where((event) => _ids.add(event.id)));
        _cursor = page.nextCursor;
        _failedRefresh = null;
        _loading = false;
      });
    } on ActivityAccessDenied {
      if (!mounted) return;
      ref.invalidate(developerAccessProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failedRefresh = refresh;
      });
    }
  }

  Future<void> _requestPage({bool refresh = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failedRefresh = null;
    });
    await _loadPage(refresh: refresh);
  }

  Future<void> _openResidence(String id) async {
    if (_openingResidence) return;
    setState(() => _openingResidence = true);
    try {
      final access = await ref
          .read(activityLogRepositoryProvider)
          .hasDeveloperAccess(widget.uid);
      if (!mounted) return;
      if (!access) {
        ref.invalidate(developerAccessProvider);
        return;
      }
      final residence = await ref.read(residenceForSupportProvider)(id);
      if (!mounted || ref.read(activityLogUserIdProvider) != widget.uid) return;

      ref.read(residenceSupportProvider.notifier).open(residence);
      context.go(AppRoutes.administration);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).appActivitySupportFailed),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingResidence = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_events.isEmpty) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      if (_failedRefresh != null) {
        return _LoadError(onRetry: () => _requestPage());
      }
    }
    return RefreshIndicator(
      onRefresh: () => _requestPage(refresh: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _events.length + 1,
        itemBuilder: (context, index) {
          if (index < _events.length) {
            final event = _events[index];
            final residenceId = event.residenceId;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child: _ActivityTile(
                event: event,
                canOpenResidence:
                    event.type == ActivityType.residenceCreated &&
                    residenceId != null,
                onOpenResidence: residenceId == null || _openingResidence
                    ? null
                    : () => _openResidence(residenceId),
              ),
            );
          }
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_failedRefresh != null) {
            return _LoadError(
              onRetry: () => _requestPage(refresh: _failedRefresh!),
            );
          }
          if (_cursor != null) {
            return Center(
              child: TextButton(
                onPressed: _requestPage,
                child: Text(strings.appActivityLoadMore),
              ),
            );
          }
          if (_events.isEmpty) {
            return Center(child: Text(strings.appActivityEmpty));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.event,
    required this.canOpenResidence,
    this.onOpenResidence,
  });

  final ActivityEvent event;
  final bool canOpenResidence;
  final VoidCallback? onOpenResidence;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final (title, icon) = switch (event.type) {
      ActivityType.accountCreated => (
        strings.appActivityAccountCreated,
        Icons.person_add_outlined,
      ),
      ActivityType.residenceCreated => (
        strings.appActivityResidenceCreated,
        Icons.apartment_outlined,
      ),
      ActivityType.residentJoined => (
        strings.appActivityResidentJoined,
        Icons.group_add_outlined,
      ),
      ActivityType.firstPostPublished => (
        strings.appActivityFirstPost,
        Icons.article_outlined,
      ),
      ActivityType.accountDeletionRequested => (
        strings.appActivityAccountDeletionRequested,
        Icons.pending_actions_outlined,
      ),
      ActivityType.accountDeleted => (
        strings.appActivityAccountDeleted,
        Icons.person_remove_outlined,
      ),
      ActivityType.residenceDeleted => (
        strings.appActivityResidenceDeleted,
        Icons.delete_outline,
      ),
      ActivityType.residencePresidentAppointed => (
        strings.appActivityResidencePresidentAppointed,
        Icons.badge_outlined,
      ),
      ActivityType.residencePresidentChanged => (
        strings.appActivityResidencePresidentChanged,
        Icons.swap_horiz_rounded,
      ),
      ActivityType.unknown => (strings.appActivityLog, Icons.history),
    };
    final date = event.occurredAt.toLocal();
    final clock = MaterialLocalizations.of(context);
    final time = clock.formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final locale = Localizations.localeOf(context).languageCode;
    final formattedDate = DarJarDateFormat.yMMMd(date, locale);
    final theme = Theme.of(context);
    return DarJarCard(
      onTap: canOpenResidence ? onOpenResidence : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  '$formattedDate · $time',
                  style: theme.textTheme.bodySmall,
                ),
                if (event.residentName case final String name)
                  _ActivityDetail(
                    label: strings.appActivityResidentName,
                    value: name,
                  ),
                if (event.phoneNumber case final String number)
                  _ActivityDetail(
                    label: strings.phoneNumber,
                    value: formatPhoneNumberForDisplay(number),
                    leftToRight: true,
                  ),
                if (event.residenceName case final String name)
                  _ActivityDetail(label: strings.residenceName, value: name),
                if (event.residenceId case final String id)
                  _ActivityDetail(
                    label: strings.appActivityResidenceId,
                    value: id,
                    leftToRight: true,
                  ),
                if (canOpenResidence)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.small),
                    child: Text(
                      strings.appActivityOpenResidence,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
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

class _ActivityDetail extends StatelessWidget {
  const _ActivityDetail({
    required this.label,
    required this.value,
    this.leftToRight = false,
  });

  final String label;
  final String value;
  final bool leftToRight;

  @override
  Widget build(BuildContext context) {
    final direction = leftToRight ? '\u2066' : '\u2068';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xSmall),
      child: Text(
        '$label · $direction$value\u2069',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(strings.appActivityLoadFailed),
          TextButton(
            onPressed: onRetry,
            child: Text(strings.accountResolutionRetry),
          ),
        ],
      ),
    );
  }
}

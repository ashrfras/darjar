import 'dart:ui' as ui;

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_loading_skeleton.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:darjar/features/documents/presentation/residence_document_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ResidenceDocumentsPage extends ConsumerStatefulWidget {
  const ResidenceDocumentsPage({super.key});

  @override
  ConsumerState<ResidenceDocumentsPage> createState() =>
      _ResidenceDocumentsPageState();
}

class _ResidenceDocumentsPageState
    extends ConsumerState<ResidenceDocumentsPage> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final documents = ref.watch(residenceDocumentsProvider);
    final attachments = ref.watch(residenceTransactionAttachmentsProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return SingleChildScrollView(
      key: const Key('residence-documents-page'),
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : AppSpacing.xLarge,
        compact ? AppSpacing.small : AppSpacing.xLarge,
        compact ? 12 : AppSpacing.xLarge,
        compact ? 28 : AppSpacing.xxxLarge,
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarSubpageHeader(
                title: localizations.documents,
                description: compact
                    ? null
                    : localizations.documentsPageDescription,
                fallbackLocation: AppRoutes.residence,
              ),
              const SizedBox(height: AppSpacing.large),
              _SectionHeader(
                title: localizations.administrativeDocuments,
                description: localizations.administrativeDocumentsDescription,
                icon: Icons.account_balance_outlined,
                onViewAll: () => _showAllAdministrativeDocuments(
                  documents.value ?? const [],
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              documents.when(
                loading: _loading,
                error: (error, stackTrace) => _loadError(
                  () => ref.invalidate(residenceDocumentsProvider),
                ),
                data: (items) {
                  final visible = items.take(5).toList();
                  return DarJarCard(
                    key: const Key('administrative-documents-section'),
                    padding: EdgeInsets.zero,
                    child: items.isEmpty
                        ? _EmptyState(
                            message: localizations.noDocuments,
                            icon: Icons.folder_open_outlined,
                          )
                        : Column(
                            children: [
                              for (
                                var index = 0;
                                index < visible.length;
                                index++
                              ) ...[
                                ResidenceDocumentRow(
                                  document: visible[index],
                                  onOpen: () => showResidenceDocumentPreview(
                                    context,
                                    ref,
                                    visible[index],
                                  ),
                                ),
                                if (index < visible.length - 1) const Divider(),
                              ],
                            ],
                          ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xLarge),
              _SectionHeader(
                title: localizations.attachedDocuments,
                description: localizations.attachedDocumentsDescription,
                icon: Icons.attach_file_rounded,
                compact: true,
                onViewAll: () {
                  final visibleAttachments =
                      attachments.value ??
                      const <ResidenceTransactionAttachment>[];
                  _showAllTransactionAttachments(visibleAttachments);
                },
              ),
              const SizedBox(height: AppSpacing.small),
              attachments.when(
                loading: _loading,
                error: (error, stackTrace) => _loadError(
                  () => ref.invalidate(residenceTransactionAttachmentsProvider),
                ),
                data: (attachments) {
                  final visible = attachments.take(3).toList();
                  return DarJarCard(
                    key: const Key('transaction-attachments-section'),
                    padding: EdgeInsets.zero,
                    child: attachments.isEmpty
                        ? _EmptyState(
                            message: localizations.noAttachedDocuments,
                            icon: Icons.attachment_outlined,
                            compact: true,
                          )
                        : Column(
                            children: [
                              for (
                                var index = 0;
                                index < visible.length;
                                index++
                              ) ...[
                                _TransactionAttachmentRow(
                                  attachment: visible[index],
                                  onOpen: () => showResidenceDocumentPreview(
                                    context,
                                    ref,
                                    visible[index].document,
                                  ),
                                ),
                                if (index < visible.length - 1) const Divider(),
                              ],
                            ],
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loading() => const DarJarLoadingSkeleton(itemCount: 2);

  Widget _loadError(VoidCallback retry) => DarJarCard(
    child: Column(
      children: [
        Text(
          AppLocalizations.of(context).documentsLoadError,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.medium),
        DarJarButton(
          label: AppLocalizations.of(context).accountResolutionRetry,
          icon: Icons.refresh_rounded,
          onPressed: retry,
        ),
      ],
    ),
  );

  Future<void> _showAllAdministrativeDocuments(
    List<ResidenceDocument> documents,
  ) {
    final localizations = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 760),
      builder: (sheetContext) => _AllDocumentsSheet(
        key: const Key('all-administrative-documents-sheet'),
        title: localizations.administrativeDocuments,
        emptyMessage: localizations.noDocuments,
        children: [
          for (final document in documents)
            ResidenceDocumentRow(
              document: document,
              onOpen: () {
                Navigator.of(sheetContext).pop();
                showResidenceDocumentPreview(context, ref, document);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _showAllTransactionAttachments(
    List<ResidenceTransactionAttachment> attachments,
  ) {
    final localizations = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 760),
      builder: (sheetContext) => _AllDocumentsSheet(
        key: const Key('all-transaction-attachments-sheet'),
        title: localizations.attachedDocuments,
        emptyMessage: localizations.noAttachedDocuments,
        compact: true,
        children: [
          for (final attachment in attachments)
            _TransactionAttachmentRow(
              attachment: attachment,
              onOpen: () {
                Navigator.of(sheetContext).pop();
                showResidenceDocumentPreview(context, ref, attachment.document);
              },
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.description,
    required this.icon,
    required this.onViewAll,
    this.compact = false,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onViewAll;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 36 : 42,
          height: compact ? 36 : 42,
          decoration: BoxDecoration(
            color: compact ? AppColors.residenceSoft : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: compact ? 20 : 23,
            color: compact ? AppColors.residence : AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: compact
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.titleLarge,
              ),
              Text(description, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        TextButton(
          key: ValueKey(
            compact
                ? 'view-all-transaction-attachments'
                : 'view-all-administrative-documents',
          ),
          onPressed: onViewAll,
          child: Text(AppLocalizations.of(context).viewAll),
        ),
      ],
    );
  }
}

class _TransactionAttachmentRow extends StatelessWidget {
  const _TransactionAttachmentRow({
    required this.attachment,
    required this.onOpen,
  });

  final ResidenceTransactionAttachment attachment;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return ListTile(
      key: ValueKey('transaction-attachment-${attachment.id}'),
      onTap: onOpen,
      leading: const Icon(
        Icons.description_outlined,
        color: AppColors.residence,
      ),
      title: Text(
        attachment.document.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${attachment.isIncome ? localizations.income : localizations.expense}'
        ' · ${DateFormat.yMMMd(localizations.localeName).format(attachment.date)}',
      ),
      trailing: onOpen == null
          ? null
          : Icon(
              Directionality.of(context) == ui.TextDirection.rtl
                  ? Icons.chevron_right_rounded
                  : Icons.chevron_left_rounded,
            ),
    );
  }
}

class _AllDocumentsSheet extends StatelessWidget {
  const _AllDocumentsSheet({
    required this.title,
    required this.emptyMessage,
    required this.children,
    this.compact = false,
    super.key,
  });

  final String title;
  final String emptyMessage;
  final List<Widget> children;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.large,
              AppSpacing.medium,
              AppSpacing.small,
              AppSpacing.medium,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: children.isEmpty
                ? _EmptyState(
                    message: emptyMessage,
                    icon: compact
                        ? Icons.attachment_outlined
                        : Icons.folder_open_outlined,
                    compact: compact,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xLarge),
                    itemCount: children.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) => children[index],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.icon,
    this.compact = false,
  });

  final String message;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(compact ? AppSpacing.large : AppSpacing.xLarge),
      child: Column(
        children: [
          Icon(icon, size: compact ? 32 : 44, color: AppColors.inkMuted),
          const SizedBox(height: AppSpacing.medium),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

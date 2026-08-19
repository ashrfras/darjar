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

class ResidenceDocumentsPage extends ConsumerStatefulWidget {
  const ResidenceDocumentsPage({super.key});

  @override
  ConsumerState<ResidenceDocumentsPage> createState() =>
      _ResidenceDocumentsPageState();
}

class _ResidenceDocumentsPageState
    extends ConsumerState<ResidenceDocumentsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearBottom);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreNearBottom)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final documents = ref.watch(residenceDocumentsPageProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return SingleChildScrollView(
      key: const Key('residence-documents-page'),
      controller: _scrollController,
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
              documents.when(
                loading: _loading,
                error: (error, stackTrace) => _loadError(
                  () => ref.invalidate(residenceDocumentsPageProvider),
                ),
                data: (items) {
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
                                index < items.length;
                                index++
                              ) ...[
                                ResidenceDocumentRow(
                                  document: items[index],
                                  onOpen: () => showResidenceDocumentPreview(
                                    context,
                                    ref,
                                    items[index],
                                  ),
                                ),
                                if (index < items.length - 1) const Divider(),
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

  void _loadMoreNearBottom() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 320) {
      return;
    }
    final documents = ref.read(residenceDocumentsPageProvider);
    if (documents.isLoading) return;
    final loadedCount = documents.value?.length ?? 0;
    final limit = ref.read(residenceDocumentsPageLimitProvider);
    if (loadedCount < limit) return;
    ref.read(residenceDocumentsPageLimitProvider.notifier).loadMore();
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.inkMuted),
          const SizedBox(height: AppSpacing.medium),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:darjar/features/documents/presentation/residence_document_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResidenceDocumentsPage extends ConsumerWidget {
  const ResidenceDocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final documents = ref.watch(residenceDocumentsProvider);
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
              documents.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xxxLarge),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stackTrace) => DarJarCard(
                  child: Column(
                    children: [
                      Text(
                        localizations.documentsLoadError,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      DarJarButton(
                        label: localizations.accountResolutionRetry,
                        icon: Icons.refresh_rounded,
                        onPressed: () =>
                            ref.invalidate(residenceDocumentsProvider),
                      ),
                    ],
                  ),
                ),
                data: (items) => DarJarCard(
                  padding: EdgeInsets.zero,
                  child: items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.xLarge),
                          child: Column(
                            children: [
                              const Icon(Icons.folder_open_outlined, size: 44),
                              const SizedBox(height: AppSpacing.medium),
                              Text(
                                localizations.noDocuments,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

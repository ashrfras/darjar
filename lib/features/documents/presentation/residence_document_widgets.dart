import 'dart:ui' as ui;

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class ResidenceDocumentRow extends StatelessWidget {
  const ResidenceDocumentRow({
    required this.document,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final ResidenceDocument document;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return InkWell(
      key: ValueKey('residence-document-${document.id}'),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.medium,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 48,
              decoration: BoxDecoration(
                color: document.isPdf
                    ? const Color(0xFFFFF0EE)
                    : AppColors.residenceSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                document.isPdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.image_outlined,
                color: document.isPdf ? AppColors.danger : AppColors.residence,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    '${residenceDocumentTypeLabel(localizations, document)}'
                    ' · ${residenceDocumentSizeLabel(document.sizeBytes)}'
                    ' · ${DateFormat.yMMMd(localizations.localeName).format(document.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                key: ValueKey('edit-residence-document-${document.id}'),
                tooltip: localizations.edit,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            if (onDelete != null)
              IconButton(
                key: ValueKey('delete-residence-document-${document.id}'),
                tooltip: localizations.delete,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            if (onEdit == null && onDelete == null)
              const Icon(
                Icons.chevron_left_rounded,
                color: AppColors.inkMuted,
                textDirection: ui.TextDirection.ltr,
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showResidenceDocumentPreview(
  BuildContext context,
  WidgetRef ref,
  ResidenceDocument document,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _ResidenceDocumentPreview(document: document),
  );
}

class _ResidenceDocumentPreview extends ConsumerStatefulWidget {
  const _ResidenceDocumentPreview({required this.document});

  final ResidenceDocument document;

  @override
  ConsumerState<_ResidenceDocumentPreview> createState() =>
      _ResidenceDocumentPreviewState();
}

class _ResidenceDocumentPreviewState
    extends ConsumerState<_ResidenceDocumentPreview> {
  late final Future<Uint8List> _download = ref
      .read(residenceDocumentsRepositoryProvider)
      .download(widget.document);
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Dialog(
      insetPadding: EdgeInsets.all(compact ? 12 : AppSpacing.xLarge),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 760),
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
                      widget.document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: localizations.close,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<Uint8List>(
                future: _download,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return _PreviewError(
                      message: localizations.documentOpenError,
                    );
                  }
                  final bytes = snapshot.data!;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: widget.document.isPdf
                            ? PdfPreview(
                                build: (_) async => bytes,
                                allowPrinting: false,
                                allowSharing: false,
                                canChangeOrientation: false,
                                canChangePageFormat: false,
                                canDebug: false,
                                pdfFileName: widget.document.originalFileName,
                                onError: (context, error) => _PreviewError(
                                  message: localizations.documentOpenError,
                                ),
                              )
                            : InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 4,
                                child: Center(
                                  child: Image.memory(
                                    bytes,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _PreviewError(
                                              message: localizations
                                                  .documentOpenError,
                                            ),
                                  ),
                                ),
                              ),
                      ),
                      PositionedDirectional(
                        end: AppSpacing.medium,
                        bottom: AppSpacing.medium,
                        child: FloatingActionButton.small(
                          key: const Key('download-document-button'),
                          tooltip: localizations.downloadDocument,
                          onPressed: _saving ? null : () => _save(bytes),
                          child: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_rounded),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(Uint8List bytes) async {
    setState(() => _saving = true);
    final localizations = AppLocalizations.of(context);
    try {
      final fileName = _safeFileName(widget.document.originalFileName);
      final file = XFile.fromData(
        bytes,
        mimeType: widget.document.contentType,
        name: fileName,
      );
      if (kIsWeb ||
          (defaultTargetPlatform != TargetPlatform.android &&
              defaultTargetPlatform != TargetPlatform.iOS)) {
        final location = await getSaveLocation(suggestedName: fileName);
        if (location == null) return;
        await file.saveTo(location.path);
      } else {
        final directory = await getDownloadsDirectory();
        if (directory == null) throw StateError('downloads-unavailable');
        await file.saveTo('${directory.path}/$fileName');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localizations.documentDownloaded)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.documentDownloadError)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

String _safeFileName(String fileName) {
  final safeName = fileName.trim().replaceAll(RegExp(r'[/\\]'), '_');
  return safeName.isEmpty ? 'document' : safeName;
}

class _PreviewError extends StatelessWidget {
  const _PreviewError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String residenceDocumentTypeLabel(
  AppLocalizations localizations,
  ResidenceDocument document,
) {
  return document.isPdf
      ? localizations.pdfDocument
      : localizations.imageDocument;
}

String residenceDocumentSizeLabel(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
  return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
}

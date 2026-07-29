import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:darjar/features/documents/presentation/residence_document_widgets.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

typedef ResidenceDocumentPicker = Future<XFile?> Function();

final residenceDocumentPickerProvider = Provider<ResidenceDocumentPicker>(
  (ref) => _pickResidenceDocument,
);

Future<XFile?> _pickResidenceDocument() {
  const types = XTypeGroup(
    label: 'PDF and images',
    extensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    mimeTypes: ['application/pdf', 'image/jpeg', 'image/png', 'image/webp'],
    uniformTypeIdentifiers: [
      'com.adobe.pdf',
      'public.jpeg',
      'public.png',
      'org.webmproject.webp',
    ],
    webWildCards: ['application/pdf', 'image/*'],
  );
  return openFile(acceptedTypeGroups: const [types]);
}

class ResidenceDocumentsManagementPage extends ConsumerStatefulWidget {
  const ResidenceDocumentsManagementPage({super.key});

  @override
  ConsumerState<ResidenceDocumentsManagementPage> createState() =>
      _ResidenceDocumentsManagementPageState();
}

class _ResidenceDocumentsManagementPageState
    extends ConsumerState<ResidenceDocumentsManagementPage> {
  bool _isUploading = false;
  double _uploadProgress = 0;
  String _uploadingTitle = '';

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final residenceContext = ref.watch(residenceContextProvider).value;
    final canManage =
        residenceContext?.activeResidence?.canManageResidence ?? false;
    final documents = ref.watch(residenceDocumentsProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;

    if (!canManage) {
      return Center(child: Text(localizations.documentsPermissionDenied));
    }

    final uploadButton = DarJarButton(
      key: const Key('upload-residence-document-button'),
      label: _isUploading
          ? localizations.documentUploading
          : localizations.uploadDocument,
      icon: Icons.upload_file_outlined,
      expanded: compact,
      onPressed: _isUploading ? null : _uploadDocument,
    );

    return SingleChildScrollView(
      key: const Key('documents-management-page'),
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : AppSpacing.xLarge,
        compact ? AppSpacing.small : AppSpacing.xLarge,
        compact ? 12 : AppSpacing.xLarge,
        compact ? 28 : AppSpacing.xxxLarge,
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 940),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarSubpageHeader(
                title: localizations.documentsManagement,
                description: compact
                    ? null
                    : localizations.documentsManagementDescription,
                fallbackLocation: AppRoutes.profile,
                action: compact ? null : uploadButton,
              ),
              if (compact) ...[
                const SizedBox(height: AppSpacing.medium),
                uploadButton,
              ],
              if (_isUploading) ...[
                const SizedBox(height: AppSpacing.medium),
                _DocumentUploadProgress(
                  title: _uploadingTitle,
                  progress: _uploadProgress,
                ),
              ],
              const SizedBox(height: AppSpacing.large),
              DarJarCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(child: Text(localizations.documentsUploadNotice)),
                  ],
                ),
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
                      IconButton(
                        onPressed: () =>
                            ref.invalidate(residenceDocumentsProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
                data: (items) => DarJarCard(
                  padding: EdgeInsets.zero,
                  child: items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.xLarge),
                          child: Text(
                            localizations.noDocuments,
                            textAlign: TextAlign.center,
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
                                onEdit: () => _editDocument(items[index]),
                                onDelete: () => _deleteDocument(items[index]),
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

  Future<void> _uploadDocument() async {
    final upload = await showModalBottomSheet<ResidenceDocumentUpload>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 620),
      builder: (context) => const _DocumentUploadSheet(),
    );
    if (upload == null || !mounted) return;

    final activeResidence = ref
        .read(residenceContextProvider)
        .value
        ?.activeResidence;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (activeResidence == null || user == null) {
      _showMessage(AppLocalizations.of(context).documentUploadError);
      return;
    }
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadingTitle = upload.title;
    });
    try {
      await ref
          .read(residenceDocumentsRepositoryProvider)
          .upload(
            residenceId: activeResidence.id,
            uploadedBy: user.uid,
            upload: upload,
            onProgress: (progress) {
              if (!mounted) return;
              setState(() => _uploadProgress = progress.clamp(0.0, 1.0));
            },
          );
      if (mounted) {
        _showMessage(AppLocalizations.of(context).documentUploaded);
      }
    } on ResidenceDocumentsFailure {
      if (mounted) {
        _showMessage(AppLocalizations.of(context).documentUploadError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
          _uploadingTitle = '';
        });
      }
    }
  }

  Future<void> _editDocument(ResidenceDocument document) async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => _EditDocumentDialog(initialTitle: document.title),
    );
    if (title == null || title.isEmpty || !mounted) return;
    final residenceId = ref
        .read(residenceContextProvider)
        .value
        ?.activeResidence
        ?.id;
    if (residenceId == null) return;
    try {
      await ref
          .read(residenceDocumentsRepositoryProvider)
          .updateTitle(
            residenceId: residenceId,
            documentId: document.id,
            title: title,
          );
      if (mounted) {
        _showMessage(AppLocalizations.of(context).documentUpdated);
      }
    } on ResidenceDocumentsFailure {
      if (mounted) {
        _showMessage(AppLocalizations.of(context).documentUpdateError);
      }
    }
  }

  Future<void> _deleteDocument(ResidenceDocument document) async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteDocument),
        content: Text(localizations.confirmDeleteDocument(document.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            key: const Key('confirm-delete-document-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final residenceId = ref
        .read(residenceContextProvider)
        .value
        ?.activeResidence
        ?.id;
    if (residenceId == null) return;
    try {
      await ref
          .read(residenceDocumentsRepositoryProvider)
          .delete(residenceId: residenceId, document: document);
      if (mounted) _showMessage(localizations.documentDeleted);
    } on ResidenceDocumentsFailure {
      if (mounted) _showMessage(localizations.documentDeleteError);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DocumentUploadProgress extends StatelessWidget {
  const _DocumentUploadProgress({required this.title, required this.progress});

  final String title;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final percentage = (progress * 100).round();
    return Semantics(
      liveRegion: true,
      label: localizations.documentUploadProgress(percentage),
      child: DarJarCard(
        key: const Key('document-upload-progress-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.documentUploadInProgress(title),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xSmall),
                      Text(
                        localizations.documentUploadProgress(percentage),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  '$percentage%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              minHeight: 7,
              borderRadius: BorderRadius.circular(999),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditDocumentDialog extends StatefulWidget {
  const _EditDocumentDialog({required this.initialTitle});

  final String initialTitle;

  @override
  State<_EditDocumentDialog> createState() => _EditDocumentDialogState();
}

class _EditDocumentDialogState extends State<_EditDocumentDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialTitle,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(localizations.editDocument),
      content: DarJarTextField(
        key: const Key('edit-document-title-field'),
        label: localizations.documentTitle,
        controller: _controller,
        textCapitalization: TextCapitalization.sentences,
        inputFormatters: [LengthLimitingTextInputFormatter(120)],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        FilledButton(
          key: const Key('save-document-title-button'),
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(localizations.saveChanges),
        ),
      ],
    );
  }
}

class _DocumentUploadSheet extends ConsumerStatefulWidget {
  const _DocumentUploadSheet();

  @override
  ConsumerState<_DocumentUploadSheet> createState() =>
      _DocumentUploadSheetState();
}

class _DocumentUploadSheetState extends ConsumerState<_DocumentUploadSheet> {
  final _titleController = TextEditingController();
  XFile? _file;
  int? _fileSize;
  String? _error;
  bool _isSelecting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Material(
      color: AppColors.canvas,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.large,
          AppSpacing.large,
          AppSpacing.large,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.large,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localizations.uploadDocument,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.large),
            DarJarTextField(
              key: const Key('document-title-field'),
              label: localizations.documentTitle,
              controller: _titleController,
              prefixIcon: Icons.title_rounded,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
            ),
            const SizedBox(height: AppSpacing.medium),
            OutlinedButton.icon(
              key: const Key('select-document-file-button'),
              onPressed: _isSelecting ? null : _selectFile,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(
                _file?.name ?? localizations.selectDocumentFile,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_fileSize case final size?) ...[
              const SizedBox(height: AppSpacing.small),
              Text(
                residenceDocumentSizeLabel(size),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
            if (_error case final error?) ...[
              const SizedBox(height: AppSpacing.medium),
              Text(
                error,
                key: const Key('document-upload-form-error'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: AppSpacing.large),
            DarJarButton(
              key: const Key('submit-document-upload-button'),
              label: localizations.uploadDocument,
              icon: Icons.upload_file_outlined,
              expanded: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFile() async {
    setState(() {
      _isSelecting = true;
      _error = null;
    });
    try {
      final file = await ref.read(residenceDocumentPickerProvider)();
      if (file == null || !mounted) return;
      final size = await file.length();
      if (!mounted) return;
      setState(() {
        _file = file;
        _fileSize = size;
      });
    } finally {
      if (mounted) setState(() => _isSelecting = false);
    }
  }

  Future<void> _submit() async {
    final localizations = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    final file = _file;
    final size = _fileSize;
    if (title.isEmpty || file == null || size == null) {
      setState(() => _error = localizations.documentFormRequired);
      return;
    }
    if (size <= 0 || size > residenceDocumentMaxSizeBytes) {
      setState(() => _error = localizations.documentTooLarge);
      return;
    }
    final contentType = residenceDocumentContentType(file.name, file.mimeType);
    if (!residenceDocumentContentTypes.contains(contentType)) {
      setState(() => _error = localizations.documentUnsupportedType);
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    Navigator.of(context).pop(
      ResidenceDocumentUpload(
        title: title,
        originalFileName: file.name,
        contentType: contentType,
        bytes: bytes,
      ),
    );
  }
}

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/images/app_image_picker.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/presentation/community_post_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _contentController = TextEditingController();
  final _eventDateController = TextEditingController();
  final _eventLocationController = TextEditingController();
  final _pollControllers = [TextEditingController(), TextEditingController()];
  final List<CommunityPostImageUpload> _selectedImages = [];
  CommunityPostKind _kind = CommunityPostKind.general;
  bool _publishing = false;
  bool _processingImages = false;

  @override
  void dispose() {
    _contentController.dispose();
    _eventDateController.dispose();
    _eventLocationController.dispose();
    for (final controller in _pollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      key: const Key('create-post-page'),
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : AppSpacing.xLarge,
          compact ? 16 : AppSpacing.xLarge,
          compact ? 12 : AppSpacing.xLarge,
          AppSpacing.xxLarge,
        ),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DarJarSubpageHeader(
                  title: localizations.createPost,
                  fallbackLocation: AppRoutes.community,
                ),
                const SizedBox(height: AppSpacing.xLarge),
                Text(
                  ar ? 'ما نوع مشاركتك؟' : 'What are you sharing?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.medium),
                _PostTypePicker(
                  selected: _kind,
                  onSelected: (kind) => setState(() => _kind = kind),
                ),
                const SizedBox(height: AppSpacing.large),
                DarJarCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(_kind.icon, color: _kind.color),
                          const SizedBox(width: AppSpacing.small),
                          Text(
                            _kind.label(context),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: _kind.color),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.large),
                      TextField(
                        key: const Key('post-content-field'),
                        controller: _contentController,
                        minLines: 5,
                        maxLines: 9,
                        decoration: InputDecoration(
                          labelText: localizations.postContent,
                          hintText: _contentHint(ar),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      _PostImagePicker(
                        images: _selectedImages,
                        processing: _processingImages,
                        onAdd: _pickImages,
                        onRemove: (image) =>
                            setState(() => _selectedImages.remove(image)),
                      ),
                      if (_kind == CommunityPostKind.poll) ...[
                        const SizedBox(height: AppSpacing.large),
                        _PollFields(
                          controllers: _pollControllers,
                          onAdd: _addPollOption,
                        ),
                      ],
                      if (_kind == CommunityPostKind.event) ...[
                        const SizedBox(height: AppSpacing.large),
                        TextField(
                          key: const Key('event-date-field'),
                          controller: _eventDateController,
                          decoration: InputDecoration(
                            labelText: ar ? 'التاريخ والوقت' : 'Date and time',
                            hintText: ar
                                ? 'مثال: السبت، الساعة 18:00'
                                : 'Example: Saturday at 18:00',
                            prefixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        TextField(
                          key: const Key('event-location-field'),
                          controller: _eventLocationController,
                          decoration: InputDecoration(
                            labelText: ar ? 'المكان' : 'Location',
                            hintText: ar
                                ? 'أين ستقام المناسبة؟'
                                : 'Where will it take place?',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                          ),
                        ),
                      ],
                      if (_publishing) ...[
                        const SizedBox(height: AppSpacing.large),
                        Semantics(
                          liveRegion: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                ar
                                    ? 'جارٍ نشر المنشور ورفع الصور…'
                                    : 'Publishing post and uploading images…',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: AppSpacing.small),
                              const LinearProgressIndicator(),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xLarge),
                      if (compact)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DarJarButton(
                              key: const Key('publish-post-button'),
                              label: localizations.publish,
                              icon: Icons.send_rounded,
                              onPressed: _publishing ? null : _publish,
                            ),
                            const SizedBox(height: AppSpacing.small),
                            DarJarButton(
                              label: localizations.cancel,
                              variant: DarJarButtonVariant.secondary,
                              onPressed: () => context.go(AppRoutes.community),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            DarJarButton(
                              label: localizations.cancel,
                              variant: DarJarButtonVariant.secondary,
                              onPressed: () => context.go(AppRoutes.community),
                            ),
                            const SizedBox(width: AppSpacing.medium),
                            DarJarButton(
                              key: const Key('publish-post-button'),
                              label: localizations.publish,
                              icon: Icons.send_rounded,
                              onPressed: _publishing ? null : _publish,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _contentHint(bool ar) => switch (_kind) {
    CommunityPostKind.question =>
      ar ? 'ما السؤال الذي تريد طرحه؟' : 'What would you like to ask?',
    CommunityPostKind.complaint =>
      ar ? 'لخّص المشكلة بوضوح' : 'Summarize the issue clearly',
    CommunityPostKind.suggestion =>
      ar ? 'ما الفكرة التي تقترحها؟' : 'What is your idea?',
    CommunityPostKind.alert =>
      ar ? 'ما الذي يجب أن ينتبه له السكان؟' : 'What should residents know?',
    CommunityPostKind.poll =>
      ar
          ? 'ما السؤال الذي ستصوّت عليه الإقامة؟'
          : 'What should the residence vote on?',
    CommunityPostKind.event =>
      ar ? 'اسم المناسبة أو النشاط' : 'Event or activity name',
    _ =>
      ar
          ? 'ماذا تريد أن تشارك مع جيرانك؟'
          : 'What would you like to share with your neighbors?',
  };

  void _addPollOption() {
    if (_pollControllers.length >= 5) return;
    setState(() => _pollControllers.add(TextEditingController()));
  }

  Future<void> _publish() async {
    final content = _contentController.text.trim();
    final pollOptions = _pollControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final ar = Localizations.localeOf(context).languageCode == 'ar';

    if (content.isEmpty) {
      _showError(ar ? 'أضف محتوى المنشور.' : 'Add post content.');
      return;
    }
    if (_kind == CommunityPostKind.poll && pollOptions.length < 2) {
      _showError(
        ar
            ? 'أضف خيارين على الأقل للاستطلاع.'
            : 'Add at least two poll options.',
      );
      return;
    }
    if (_kind == CommunityPostKind.event &&
        (_eventDateController.text.trim().isEmpty ||
            _eventLocationController.text.trim().isEmpty)) {
      _showError(
        ar ? 'أضف موعد المناسبة ومكانها.' : 'Add the event date and location.',
      );
      return;
    }

    setState(() => _publishing = true);
    try {
      await ref
          .read(communityActionsProvider)
          .createPost(
            content: content,
            kind: _kind,
            pollOptions: pollOptions,
            images: _selectedImages,
            eventDate: _eventDateController.text.trim().isEmpty
                ? null
                : _eventDateController.text.trim(),
            eventLocation: _eventLocationController.text.trim().isEmpty
                ? null
                : _eventLocationController.text.trim(),
          );
      if (mounted) context.go(AppRoutes.community);
    } on CommunityFailure {
      if (!mounted) return;
      _showError(
        ar ? 'تعذّر نشر المنشور. حاول مجددًا.' : 'Could not publish the post.',
      );
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImages() async {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final remaining =
        FirebaseCommunityRepository.maxImages - _selectedImages.length;
    if (remaining <= 0) return;
    List<AppPickedImage> files;
    try {
      files = await pickAppImages(limit: remaining);
    } catch (_) {
      if (mounted) {
        _showError(
          ar
              ? 'تعذّر فتح مكتبة الصور. تحقق من صلاحية الوصول إلى الصور.'
              : 'Could not open the photo library. Check photo access.',
        );
      }
      return;
    }
    if (files.isEmpty) return;
    final additions = <CommunityPostImageUpload>[];
    setState(() => _processingImages = true);
    try {
      for (final file in files.take(remaining)) {
        final bytes = file.bytes;
        final contentType = _imageContentType(file.name, file.mimeType);
        if (contentType.isEmpty ||
            bytes.isEmpty ||
            bytes.lengthInBytes > communityImageMaxSourceSizeBytes) {
          if (mounted) {
            _showError(
              ar
                  ? 'يجب أن تكون الصورة JPG أو PNG أو WebP وأقل من 8MB.'
                  : 'Images must be JPG, PNG, or WebP and under 8MB.',
            );
          }
          continue;
        }
        try {
          final compressed = await compute(compressCommunityImageBytes, bytes);
          if (compressed.lengthInBytes > communityImageMaxStoredSizeBytes) {
            throw const CommunityFailure('compressed-image-too-large');
          }
          additions.add(
            CommunityPostImageUpload(
              fileName: '${file.name.split('.').first}.jpg',
              contentType: 'image/jpeg',
              bytes: compressed,
            ),
          );
        } catch (_) {
          if (mounted) {
            _showError(
              ar
                  ? 'تعذّرت معالجة إحدى الصور.'
                  : 'One of the images could not be processed.',
            );
          }
        }
      }
      if (mounted && additions.isNotEmpty) {
        setState(() => _selectedImages.addAll(additions));
      }
    } finally {
      if (mounted) setState(() => _processingImages = false);
    }
  }
}

String _imageContentType(String fileName, String? reportedType) {
  if (FirebaseCommunityRepository.acceptedImageTypes.contains(reportedType)) {
    return reportedType!;
  }
  final extension = fileName.split('.').last.toLowerCase();
  return switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => '',
  };
}

class _PostImagePicker extends StatelessWidget {
  const _PostImagePicker({
    required this.images,
    required this.processing,
    required this.onAdd,
    required this.onRemove,
  });

  final List<CommunityPostImageUpload> images;
  final bool processing;
  final VoidCallback onAdd;
  final ValueChanged<CommunityPostImageUpload> onRemove;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (images.isNotEmpty) ...[
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.small),
              itemBuilder: (context, index) {
                final image = images[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      child: Image.memory(
                        image.bytes,
                        width: 112,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                    PositionedDirectional(
                      top: 4,
                      end: 4,
                      child: IconButton.filled(
                        key: ValueKey('remove-post-image-$index'),
                        tooltip: ar ? 'إزالة الصورة' : 'Remove photo',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => onRemove(image),
                        icon: const Icon(Icons.close_rounded, size: 17),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.small),
        ],
        if (images.length < FirebaseCommunityRepository.maxImages)
          OutlinedButton.icon(
            key: const Key('add-post-images-button'),
            onPressed: processing ? null : onAdd,
            icon: processing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              processing
                  ? (ar ? 'جارٍ تحسين الصور…' : 'Optimizing images…')
                  : (ar ? 'إضافة صور (حتى 4)' : 'Add photos (up to 4)'),
            ),
          ),
      ],
    );
  }
}

class _PostTypePicker extends StatelessWidget {
  const _PostTypePicker({required this.selected, required this.onSelected});

  final CommunityPostKind selected;
  final ValueChanged<CommunityPostKind> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: [
        for (final kind in CommunityPostKind.values.where(
          (kind) => kind != CommunityPostKind.announcement,
        ))
          ChoiceChip(
            key: ValueKey('post-type-${kind.name}'),
            avatar: Icon(
              kind.icon,
              size: 16,
              color: selected == kind ? Colors.white : kind.color,
            ),
            label: Text(kind.label(context)),
            selected: selected == kind,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            labelPadding: const EdgeInsetsDirectional.only(start: 2, end: 6),
            selectedColor: kind.color,
            labelStyle: TextStyle(
              fontSize: 13,
              color: selected == kind ? Colors.white : AppColors.ink,
            ),
            side: BorderSide(
              color: selected == kind ? kind.color : AppColors.outline,
            ),
            onSelected: (_) => onSelected(kind),
          ),
      ],
    );
  }
}

class _PollFields extends StatelessWidget {
  const _PollFields({required this.controllers, required this.onAdd});

  final List<TextEditingController> controllers;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ar ? 'خيارات التصويت' : 'Poll options',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.small),
        for (var index = 0; index < controllers.length; index++) ...[
          TextField(
            key: ValueKey('poll-option-field-$index'),
            controller: controllers[index],
            decoration: InputDecoration(
              labelText: ar ? 'الخيار ${index + 1}' : 'Option ${index + 1}',
              prefixIcon: const Icon(Icons.radio_button_unchecked_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
        ],
        if (controllers.length < 5)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('add-poll-option-button'),
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(ar ? 'إضافة خيار' : 'Add option'),
            ),
          ),
      ],
    );
  }
}

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/presentation/community_post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _eventDateController = TextEditingController();
  final _eventLocationController = TextEditingController();
  final _pollControllers = [TextEditingController(), TextEditingController()];
  CommunityPostKind _kind = CommunityPostKind.general;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
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
                Row(
                  children: [
                    IconButton(
                      tooltip: localizations.cancel,
                      onPressed: () => context.go(AppRoutes.community),
                      icon: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_forward_rounded
                            : Icons.arrow_back_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.createPost,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            ar
                                ? 'اختر نوع المشاركة وأضف التفاصيل المهمة لجيرانك.'
                                : 'Choose a post type and add the useful details.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      DarJarTextField(
                        label: localizations.postTitle,
                        hint: _titleHint(ar),
                        controller: _titleController,
                      ),
                      const SizedBox(height: AppSpacing.large),
                      TextField(
                        controller: _bodyController,
                        minLines: 5,
                        maxLines: 9,
                        decoration: InputDecoration(
                          labelText: localizations.postBody,
                          hintText: _bodyHint(ar),
                          alignLabelWithHint: true,
                        ),
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
                      const SizedBox(height: AppSpacing.large),
                      _PrivacyNotice(),
                      const SizedBox(height: AppSpacing.xLarge),
                      if (compact)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DarJarButton(
                              key: const Key('publish-post-button'),
                              label: localizations.publish,
                              icon: Icons.send_rounded,
                              onPressed: _publish,
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
                              onPressed: _publish,
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

  String _titleHint(bool ar) => switch (_kind) {
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
    _ => ar ? 'اكتب عنواناً واضحاً' : 'Write a clear title',
  };

  String _bodyHint(bool ar) => ar
      ? 'أضف سياقاً مفيداً وواضحاً لسكان الإقامة...'
      : 'Add clear, useful context for residents…';

  void _addPollOption() {
    if (_pollControllers.length >= 5) return;
    setState(() => _pollControllers.add(TextEditingController()));
  }

  void _publish() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final pollOptions = _pollControllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final ar = Localizations.localeOf(context).languageCode == 'ar';

    if (title.isEmpty || body.isEmpty) {
      _showError(
        ar ? 'أضف عنواناً وتفاصيل للمنشور.' : 'Add a title and details.',
      );
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

    ref
        .read(communityPostsProvider.notifier)
        .createPost(
          title: title,
          body: body,
          kind: _kind,
          pollOptions: pollOptions,
          eventDate: _eventDateController.text.trim().isEmpty
              ? null
              : _eventDateController.text.trim(),
          eventLocation: _eventLocationController.text.trim().isEmpty
              ? null
              : _eventLocationController.text.trim(),
        );
    context.go(AppRoutes.community);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
              size: 18,
              color: selected == kind ? Colors.white : kind.color,
            ),
            label: Text(kind.label(context)),
            selected: selected == kind,
            selectedColor: kind.color,
            labelStyle: TextStyle(
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

class _PrivacyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              ar
                  ? 'سيظهر هذا المنشور لسكان إقامة الياسمين فقط.'
                  : 'This post is visible only to Yasmeen Residence residents.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

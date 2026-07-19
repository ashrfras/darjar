import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/community/data/community_repository.dart';
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

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      key: const Key('create-post-page'),
      padding: const EdgeInsets.all(AppSpacing.xLarge),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarPageHeader(
                title: localizations.createPost,
                description: localizations.createPostDescription,
              ),
              const SizedBox(height: AppSpacing.xLarge),
              DarJarCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DarJarTextField(
                      label: localizations.postTitle,
                      hint: localizations.postTitleHint,
                      controller: _titleController,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    TextField(
                      controller: _bodyController,
                      minLines: 5,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: localizations.postBody,
                        hintText: localizations.postBodyHint,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xLarge),
                    Row(
                      children: [
                        Expanded(
                          child: DarJarButton(
                            key: const Key('publish-post-button'),
                            label: localizations.publish,
                            onPressed: _publish,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        DarJarButton(
                          label: localizations.cancel,
                          variant: DarJarButtonVariant.secondary,
                          onPressed: () => context.go(AppRoutes.community),
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
    );
  }

  void _publish() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    ref
        .read(communityPostsProvider.notifier)
        .createPost(title: title, body: body);
    context.go(AppRoutes.community);
  }
}

import 'dart:async';
import 'dart:math';

import 'package:darjar/features/community/presentation/community_post_action_icon.dart';
import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/presentation/community_post_share_image.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

enum _PostShareFormat { image, text }

class CommunityPostShareButton extends ConsumerStatefulWidget {
  const CommunityPostShareButton({required this.post, super.key});

  final CommunityPost post;

  @override
  ConsumerState<CommunityPostShareButton> createState() =>
      _CommunityPostShareButtonState();
}

class _CommunityPostShareButtonState
    extends ConsumerState<CommunityPostShareButton> {
  bool _sharing = false;
  bool _choosing = false;

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context);
    return IconButton(
      key: ValueKey('share-${widget.post.id}'),
      onPressed: _sharing || _choosing ? null : _chooseFormat,
      tooltip: _sharing ? copy.postSharePreparing : copy.postShare,
      color: AppColors.inkMuted,
      iconSize: 20,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      visualDensity: VisualDensity.standard,
      icon: _sharing
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: copy.postSharePreparing,
              ),
            )
          : const CommunityPostActionIcon(Icons.ios_share_rounded),
    );
  }

  Future<void> _chooseFormat() async {
    if (_choosing || _sharing) return;
    setState(() => _choosing = true);
    _PostShareFormat? format;
    try {
      format = await showModalBottomSheet<_PostShareFormat>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: AppColors.surface,
        constraints: const BoxConstraints(maxWidth: 620),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
        ),
        builder: (_) => const _PostShareSheet(),
      );
    } finally {
      if (mounted) setState(() => _choosing = false);
    }
    if (mounted && format != null) await _share(format);
  }

  Future<void> _share(_PostShareFormat format) async {
    if (_sharing) return;
    final copy = AppLocalizations.of(context);
    final direction = Directionality.of(context);
    final locale = Localizations.localeOf(context);
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    final post = widget.post;
    final navigator = Navigator.of(context, rootNavigator: true);
    DialogRoute<void>? preparingRoute;
    void closePreparing() {
      final route = preparingRoute;
      preparingRoute = null;
      if (route != null && route.isActive && navigator.mounted) {
        navigator.removeRoute(route);
      }
    }

    setState(() => _sharing = true);
    try {
      if (format == _PostShareFormat.text) {
        await SharePlus.instance.share(
          ShareParams(text: post.content, sharePositionOrigin: origin),
        );
        return;
      }
      preparingRoute = DialogRoute<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _ImagePreparingDialog(),
      );
      unawaited(navigator.push(preparingRoute!));
      // Capture the scope before loading attachments. Text sharing deliberately
      // needs neither a residence lookup nor image downloads.
      final residenceFuture = ref.read(residenceContextProvider.future);
      final repository = ref.read(communityRepositoryProvider);
      final residence = (await residenceFuture).activeResidence;
      // Paint the loading state before any synchronous image layout/encoding.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      if (residence == null || residence.name.trim().isEmpty) {
        throw StateError('No active residence');
      }
      final images = <Uint8List>[];
      for (final path in post.imagePaths) {
        if (path.startsWith('assets/')) {
          final data = await rootBundle.load(path);
          images.add(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
        } else {
          images.add(
            await repository
                .downloadImage(path)
                .timeout(const Duration(seconds: 30)),
          );
        }
      }
      final png = await CommunityPostShareImage.render(
        residenceName: residence.name,
        content: post.content,
        textDirection: direction,
        locale: locale,
        images: images,
      );
      if (!mounted) return;
      closePreparing();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(png, mimeType: 'image/png')],
          fileNameOverrides: [
            'دارجار-منشور-${100 + Random().nextInt(900)}.png',
          ],
          sharePositionOrigin: origin,
        ),
      );
    } catch (error) {
      closePreparing();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              error is PostShareImageTooLarge
                  ? copy.postShareTooLarge
                  : format == _PostShareFormat.text
                  ? copy.postShareTextFailed
                  : copy.postShareFailed,
            ),
          ),
        );
      }
    } finally {
      closePreparing();
      if (mounted) setState(() => _sharing = false);
    }
  }
}

class _PostShareSheet extends StatelessWidget {
  const _PostShareSheet();

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const Key('post-share-sheet'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xLarge,
          0,
          AppSpacing.xLarge,
          AppSpacing.xLarge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              copy.postShareTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              copy.postShareDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.large),
            _option(
              context,
              format: _PostShareFormat.image,
              icon: Icons.image_outlined,
              title: copy.postShareImage,
              description: copy.postShareImageDescription,
            ),
            const SizedBox(height: AppSpacing.small),
            _option(
              context,
              format: _PostShareFormat.text,
              icon: Icons.notes_rounded,
              title: copy.postShareText,
              description: copy.postShareTextDescription,
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required _PostShareFormat format,
    required IconData icon,
    required String title,
    required String description,
  }) => ListTile(
    key: ValueKey('post-share-${format.name}'),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.medium,
      vertical: AppSpacing.small,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      side: BorderSide(color: AppColors.outline),
    ),
    leading: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    ),
    title: Text(title),
    subtitle: Text(description),
    onTap: () => Navigator.of(context).pop(format),
  );
}

class _ImagePreparingDialog extends StatelessWidget {
  const _ImagePreparingDialog();

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: const Key('post-share-image-loading'),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        title: Text(copy.postSharePreparingImage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              semanticsLabel: copy.postSharePreparingImage,
            ),
            const SizedBox(height: AppSpacing.large),
            Text(copy.postSharePreparingImageDescription),
          ],
        ),
      ),
    );
  }
}

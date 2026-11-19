import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/community/presentation/community_post_action_icon.dart';
import 'package:flutter/material.dart';

class CommunityPostSaveButton extends StatefulWidget {
  const CommunityPostSaveButton({
    required this.post,
    required this.onSave,
    super.key,
  });

  final CommunityPost post;
  final Future<void> Function() onSave;

  @override
  State<CommunityPostSaveButton> createState() =>
      _CommunityPostSaveButtonState();
}

class _CommunityPostSaveButtonState extends State<CommunityPostSaveButton> {
  bool _requestInFlight = false;
  // The write can finish before the updated post reaches the UI stream.
  bool? _pendingSaved;

  bool get _saving => _requestInFlight || _pendingSaved != null;

  @override
  void didUpdateWidget(covariant CommunityPostSaveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_requestInFlight && widget.post.isSaved == _pendingSaved) {
      _pendingSaved = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppLocalizations.of(context);
    return IconButton(
      key: ValueKey('save-${widget.post.id}'),
      iconSize: 20,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      visualDensity: VisualDensity.standard,
      tooltip: _saving ? copy.profileSaving : copy.savePost,
      onPressed: _saving ? null : _save,
      color: widget.post.isSaved ? AppColors.primary : AppColors.inkMuted,
      icon: _saving
          ? SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: copy.profileSaving,
              ),
            )
          : CommunityPostActionIcon(
              widget.post.isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _requestInFlight = true;
      _pendingSaved = !widget.post.isSaved;
    });
    var succeeded = false;
    try {
      await widget.onSave();
      succeeded = true;
    } on CommunityFailure {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).communityActionFailed),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _requestInFlight = false;
          if (!succeeded || widget.post.isSaved == _pendingSaved) {
            _pendingSaved = null;
          }
        });
      }
    }
  }
}

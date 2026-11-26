import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:flutter/material.dart';

Future<void> showEditPostDialog(
  BuildContext context, {
  required CommunityPost post,
  required Future<void> Function(String content) onSave,
}) async {
  if (!post.isCurrentUser || post.isSystem) return;
  final localizations = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final expired =
      !isCommunityPostEditOpen(post.createdAt, DateTime.now()) ||
      await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => _EditPostDialog(post: post, onSave: onSave),
          ) ==
          true;
  if (expired && messenger.mounted) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(localizations.postEditExpired),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _EditPostDialog extends StatefulWidget {
  const _EditPostDialog({required this.post, required this.onSave});

  final CommunityPost post;
  final Future<void> Function(String content) onSave;

  @override
  State<_EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<_EditPostDialog> {
  late final _controller = TextEditingController(text: widget.post.content);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(localizations.editPost),
        scrollable: true,
        content: SizedBox(
          width: 440,
          child: TextField(
            controller: _controller,
            autofocus: true,
            readOnly: _saving,
            minLines: 3,
            maxLines: 7,
            decoration: InputDecoration(
              labelText: localizations.postContent,
              alignLabelWithHint: true,
              errorText: _error,
              errorMaxLines: 3,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(localizations.saveChanges),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final localizations = AppLocalizations.of(context);
    final content = _controller.text.trim();
    if (!isCommunityPostEditOpen(widget.post.createdAt, DateTime.now())) {
      Navigator.of(context).pop(true);
      return;
    }
    if (content.isEmpty || content.length > 5000) {
      setState(() => _error = localizations.postEditInvalidContent);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(content);
      if (mounted) Navigator.of(context).pop();
    } on CommunityFailure catch (error) {
      if (!mounted) return;
      if (error.code == 'post-edit-expired' ||
          !isCommunityPostEditOpen(widget.post.createdAt, DateTime.now())) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _saving = false;
        _error = localizations.postEditFailed;
      });
    }
  }
}

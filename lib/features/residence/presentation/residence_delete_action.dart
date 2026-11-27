import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/features/auth/data/auth_failure.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_deletion_repository.dart';
import 'package:darjar/features/residence/presentation/residence_progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResidenceDeleteAction extends ConsumerStatefulWidget {
  const ResidenceDeleteAction({
    required this.target,
    required this.enabled,
    super.key,
  });

  final ResidenceDeletionTarget target;
  final bool enabled;

  @override
  ConsumerState<ResidenceDeleteAction> createState() =>
      _ResidenceDeleteActionState();
}

class _ResidenceDeleteActionState extends ConsumerState<ResidenceDeleteAction> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final enabled = widget.enabled && !_deleting;
    return ListTile(
      key: const Key('delete-residence-row'),
      enabled: enabled,
      onTap: enabled ? _confirm : null,
      leading: const Icon(Icons.delete_outline_rounded),
      title: Text(
        strings.residenceDelete,
        style: enabled
            ? TextStyle(color: Theme.of(context).colorScheme.error)
            : null,
      ),
      subtitle: Text(strings.residenceDeleteDescription),
      trailing: Icon(
        Icons.chevron_left_rounded,
        color: AppColors.inkMuted,
        textDirection: TextDirection.ltr,
      ),
    );
  }

  Future<void> _confirm() async {
    final strings = AppLocalizations.of(context);
    final target = widget.target;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.residenceDelete),
        content: Text(strings.residenceDeleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.residenceDelete),
          ),
        ],
      ),
    );
    if (!mounted ||
        confirmed != true ||
        _deleting ||
        !widget.enabled ||
        target != widget.target) {
      return;
    }
    if (ref.read(canDeleteResidenceProvider(target)).value != true) return;

    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _deleting = true);
    try {
      await showResidenceProgress(
        context,
        label: strings.residenceDeleting,
        run: () => ref.read(deleteResidenceProvider)(target.residenceId),
      );
      container.invalidate(residenceContextProvider);
      if (messenger.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.residenceDeleted)),
        );
      }
    } catch (error) {
      if (!mounted) return;
      final joined =
          error is AuthFailure &&
          error.code == 'residence-has-joined-residents';
      if (joined) ref.invalidate(canDeleteResidenceProvider(target));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            joined
                ? strings.residenceDeleteBlocked
                : strings.residenceDeleteError,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }
}

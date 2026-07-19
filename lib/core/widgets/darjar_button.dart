import 'package:darjar/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum DarJarButtonVariant { primary, secondary }

class DarJarButton extends StatelessWidget {
  const DarJarButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = DarJarButtonVariant.primary,
    this.expanded = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DarJarButtonVariant variant;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon),
              const SizedBox(width: AppSpacing.small),
              Text(label),
            ],
          );
    final button = switch (variant) {
      DarJarButtonVariant.primary => FilledButton(
        onPressed: onPressed,
        child: child,
      ),
      DarJarButtonVariant.secondary => OutlinedButton(
        onPressed: onPressed,
        child: child,
      ),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

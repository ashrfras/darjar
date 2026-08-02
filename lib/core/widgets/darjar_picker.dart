import 'dart:math' as math;

import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class DarJarPickerField<T> extends StatelessWidget {
  const DarJarPickerField({
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.placeholder,
    required this.onOpen,
    required this.onChanged,
    this.icon = Icons.expand_more_rounded,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
    super.key,
  });

  final String label;
  final T? value;
  final String? valueLabel;
  final String placeholder;
  final IconData icon;
  final IconData? prefixIcon;
  final Future<T?> Function() onOpen;
  final ValueChanged<T> onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: ValueKey(value),
      initialValue: value,
      validator: validator,
      builder: (field) {
        Future<void> openPicker() async {
          if (!enabled) return;
          final selected = await onOpen();
          if (selected == null) return;
          field.didChange(selected);
          onChanged(selected);
        }

        return Semantics(
          button: true,
          enabled: enabled,
          label: label,
          value: valueLabel,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            onTap: enabled ? openPicker : null,
            child: InputDecorator(
              isEmpty: false,
              decoration: InputDecoration(
                labelText: label,
                errorText: field.errorText,
                prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
                suffixIcon: Icon(icon, color: AppColors.inkMuted),
                enabled: enabled,
              ),
              child: Text(
                valueLabel ?? placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: valueLabel == null
                      ? AppColors.inkMuted
                      : AppColors.ink,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<T?> showDarJarPickerSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  double height = 560,
  Key? sheetKey,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.ink.withValues(alpha: 0.32),
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (context) {
      final availableHeight = MediaQuery.sizeOf(context).height * 0.72;
      return SizedBox(
        key: sheetKey,
        height: math.min(height, availableHeight),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.large),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x2417151D),
                blurRadius: 32,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.large,
              top: AppSpacing.small,
              right: AppSpacing.large,
              bottom: AppSpacing.large,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outline,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                Expanded(child: builder(context)),
              ],
            ),
          ),
        ),
      );
    },
  );
}

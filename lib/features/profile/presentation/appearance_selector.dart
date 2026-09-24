import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class DarJarAppearanceSelector extends StatelessWidget {
  const DarJarAppearanceSelector({
    required this.selectedMode,
    required this.onSelected,
    super.key,
  });

  final ThemeMode selectedMode;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final selected = _options(
      localizations,
    ).firstWhere((option) => option.mode == selectedMode);
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: localizations.appearance,
      value: selected.label,
      child: InkWell(
        key: const Key('theme-mode-selector'),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: () => _showAppearanceSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xSmall),
          child: Row(
            children: [
              Icon(Icons.brightness_6_outlined, color: colors.onSurfaceVariant),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Text(
                  localizations.appearance,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                selected.label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.xSmall),
              Icon(
                Icons.chevron_left_rounded,
                size: 21,
                color: colors.onSurfaceVariant,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAppearanceSheet(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.34),
      builder: (sheetContext) => _AppearanceSheet(
        options: _options(localizations),
        selectedMode: selectedMode,
      ),
    );
    if (selected != null && selected != selectedMode) onSelected(selected);
  }

  List<_ThemeModeOption> _options(AppLocalizations localizations) => [
    _ThemeModeOption(
      mode: ThemeMode.system,
      icon: Icons.brightness_auto_rounded,
      label: localizations.themeSystem,
    ),
    _ThemeModeOption(
      mode: ThemeMode.light,
      icon: Icons.light_mode_outlined,
      label: localizations.themeLight,
    ),
    _ThemeModeOption(
      mode: ThemeMode.dark,
      icon: Icons.dark_mode_outlined,
      label: localizations.themeDark,
    ),
  ];
}

class _AppearanceSheet extends StatelessWidget {
  const _AppearanceSheet({required this.options, required this.selectedMode});

  final List<_ThemeModeOption> options;
  final ThemeMode selectedMode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.large,
          AppSpacing.small,
          AppSpacing.large,
          AppSpacing.large,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              AppLocalizations.of(context).appearance,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.medium),
            for (var index = 0; index < options.length; index++) ...[
              _AppearanceOptionTile(
                option: options[index],
                selected: options[index].mode == selectedMode,
              ),
              if (index < options.length - 1)
                Divider(color: colors.outlineVariant),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppearanceOptionTile extends StatelessWidget {
  const _AppearanceOptionTile({required this.option, required this.selected});

  final _ThemeModeOption option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
      leading: Icon(
        option.icon,
        color: selected ? colors.primary : colors.onSurfaceVariant,
      ),
      title: Text(option.label),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: colors.primary)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      onTap: () => Navigator.pop(context, option.mode),
    );
  }
}

class _ThemeModeOption {
  const _ThemeModeOption({
    required this.mode,
    required this.icon,
    required this.label,
  });

  final ThemeMode mode;
  final IconData icon;
  final String label;
}

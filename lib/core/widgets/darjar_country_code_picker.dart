import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/utils/phone_number.dart';
import 'package:darjar/core/widgets/darjar_picker.dart';
import 'package:flutter/material.dart';

class DarJarCountryCodePickerField extends StatelessWidget {
  const DarJarCountryCodePickerField({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DarJarPickerField<String>(
      value: value,
      valueLabel: value,
      label: label,
      placeholder: '+212',
      onChanged: onChanged,
      onOpen: () =>
          showDarJarCountryCodePicker(context: context, selectedCode: value),
    );
  }
}

Future<String?> showDarJarCountryCodePicker({
  required BuildContext context,
  String selectedCode = '+212',
}) {
  final localizations = AppLocalizations.of(context);
  return showDarJarPickerSheet<String>(
    context: context,
    title: localizations.countryCodePickerTitle,
    height: 480,
    sheetKey: const Key('country-code-picker-sheet'),
    builder: (context) => ListView(
      key: const Key('country-code-options'),
      children: [
        for (final group in CountryCallingCodeGroup.values) ...[
          _CountryGroupTitle(label: _groupLabel(localizations, group)),
          for (final country in supportedCountries.where(
            (country) => country.group == group,
          )) ...[
            _CountryOption(
              country: country,
              selected: country.code == selectedCode,
              onTap: () => Navigator.pop(context, country.code),
            ),
            const Divider(),
          ],
        ],
      ],
    ),
  );
}

class _CountryGroupTitle extends StatelessWidget {
  const _CountryGroupTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.medium,
        AppSpacing.large,
        AppSpacing.medium,
        AppSpacing.small,
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _CountryOption extends StatelessWidget {
  const _CountryOption({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final CountryCallingCode country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return InkWell(
      key: ValueKey('country-code-option-${country.code}'),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.medium,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 54,
              child: Text(
                country.flag,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                country.localizedName(localizations.localeName),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                country.code,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? AppColors.primary : AppColors.inkMuted,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: AppSpacing.small),
              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }
}

String _groupLabel(
  AppLocalizations localizations,
  CountryCallingCodeGroup group,
) {
  return switch (group) {
    CountryCallingCodeGroup.arab => localizations.countryGroupArab,
    CountryCallingCodeGroup.europe => localizations.countryGroupEurope,
    CountryCallingCodeGroup.northAmerica =>
      localizations.countryGroupNorthAmerica,
  };
}

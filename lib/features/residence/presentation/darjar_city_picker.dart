import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_picker.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/residence/presentation/moroccan_cities.dart';
import 'package:flutter/material.dart';

class DarJarCityPickerField extends StatelessWidget {
  const DarJarCityPickerField({
    required this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    super.key,
  });

  final String? value;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final selectedCity = value == null
        ? null
        : moroccanCities.where((city) => city.id == value).firstOrNull;
    return DarJarPickerField<String>(
      value: value,
      valueLabel: selectedCity?.localizedName(localizations),
      label: localizations.city,
      placeholder: localizations.citySelectHint,
      prefixIcon: Icons.location_city_outlined,
      enabled: enabled,
      validator: validator,
      onChanged: onChanged,
      onOpen: () =>
          showDarJarCityPicker(context: context, selectedCityId: value),
    );
  }
}

Future<String?> showDarJarCityPicker({
  required BuildContext context,
  String? selectedCityId,
}) {
  final localizations = AppLocalizations.of(context);
  return showDarJarPickerSheet<String>(
    context: context,
    title: localizations.cityPickerTitle,
    sheetKey: const Key('city-picker-sheet'),
    builder: (_) => _CitySearch(selectedCityId: selectedCityId),
  );
}

class _CitySearch extends StatefulWidget {
  const _CitySearch({this.selectedCityId});

  final String? selectedCityId;

  @override
  State<_CitySearch> createState() => _CitySearchState();
}

class _CitySearchState extends State<_CitySearch> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final normalizedQuery = _normalizeSearchText(_query);
    final results = normalizedQuery.isEmpty
        ? const <MoroccanCity>[]
        : moroccanCities
              .where((city) {
                return _normalizeSearchText(
                      city.nameAr,
                    ).contains(normalizedQuery) ||
                    _normalizeSearchText(
                      city.nameLatin,
                    ).contains(normalizedQuery);
              })
              .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DarJarTextField(
          key: const Key('city-search-field'),
          label: localizations.citySearchLabel,
          hint: localizations.citySearchHint,
          labelAsHint: true,
          prefixIcon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: AppSpacing.medium),
        Expanded(
          child: normalizedQuery.isEmpty
              ? _EmptyState(
                  icon: Icons.travel_explore_rounded,
                  message: localizations.citySearchPrompt,
                )
              : results.isEmpty
              ? _EmptyState(
                  icon: Icons.location_off_outlined,
                  message: localizations.citySearchNoResults,
                )
              : ListView.separated(
                  key: const Key('city-search-results'),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final city = results[index];
                    final selected = city.id == widget.selectedCityId;
                    return _PickerOption(
                      key: ValueKey('city-option-${city.id}'),
                      label: city.localizedName(localizations),
                      selected: selected,
                      onTap: () => Navigator.pop(context, city.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.medium,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? AppColors.primarySoft : AppColors.canvas,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_city_outlined,
                color: selected ? AppColors.primary : AppColors.inkMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xLarge),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 30),
            const SizedBox(height: AppSpacing.small),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

String _normalizeSearchText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll(RegExp('[àáâä]'), 'a')
      .replaceAll(RegExp('[èéêë]'), 'e')
      .replaceAll(RegExp('[ìíîï]'), 'i')
      .replaceAll(RegExp('[òóôö]'), 'o')
      .replaceAll(RegExp('[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]'), '');
}

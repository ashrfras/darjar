import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_international_phone_field.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/core/utils/phone_number.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:darjar/features/directory/data/service_categories_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateServicePage extends ConsumerStatefulWidget {
  const CreateServicePage({this.entryId, super.key});

  final String? entryId;

  @override
  ConsumerState<CreateServicePage> createState() => _CreateServicePageState();
}

class _CreateServicePageState extends ConsumerState<CreateServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _professionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  String _countryCode = '+212';
  String? _categoryId;
  final Set<String> _subcategoryIds = {};
  bool _saving = false;
  bool _initializedFromEntry = false;

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _phoneController.dispose();
    _neighborhoodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final editing = widget.entryId != null;
    DirectoryEntry? entry;
    if (editing) {
      ref.watch(directoryEntriesProvider);
      entry = ref.read(directoryEntriesProvider.notifier).find(widget.entryId!);
      if (entry != null && !_initializedFromEntry) {
        _populateFrom(entry);
      }
    }
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    final categoriesState = ref.watch(serviceCategoriesProvider);
    final categories = categoriesState.value ?? const <ServiceCategory>[];
    final languageCode = Localizations.localeOf(context).languageCode;
    final selectedCategory = categories
        .where((category) => category.id == _categoryId)
        .firstOrNull;
    final compact = MediaQuery.sizeOf(context).width < 600;

    if (editing &&
        (entry == null ||
            entry.createdBy.isEmpty ||
            entry.createdBy != currentUser?.uid)) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.xLarge),
          children: [
            DarJarSubpageHeader(fallbackLocation: AppRoutes.directory),
            const SizedBox(height: AppSpacing.large),
            Center(child: Text(localizations.directoryProfileNotFound)),
          ],
        ),
      );
    }

    return Scaffold(
      key: Key(editing ? 'edit-service-page' : 'create-service-page'),
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : AppSpacing.xLarge,
          compact ? 16 : AppSpacing.xLarge,
          compact ? 12 : AppSpacing.xLarge,
          AppSpacing.xxLarge,
        ),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DarJarSubpageHeader(
                  title: editing
                      ? localizations.editService
                      : localizations.createService,
                  fallbackLocation: editing
                      ? AppRoutes.directoryProfile(widget.entryId!)
                      : AppRoutes.directory,
                ),
                const SizedBox(height: AppSpacing.xLarge),
                Text(
                  editing
                      ? localizations.editServiceDescription
                      : localizations.createServiceDescription,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.large),
                DarJarCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DarJarTextField(
                          key: const Key('service-name-field'),
                          controller: _nameController,
                          label: localizations.serviceName,
                          hint: localizations.serviceNameHint,
                        ),
                        const SizedBox(height: AppSpacing.large),
                        DropdownButtonFormField<String>(
                          key: const Key('service-category-field'),
                          initialValue: _categoryId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: localizations.serviceCategory,
                            prefixIcon: const Icon(Icons.category_outlined),
                          ),
                          hint: Text(localizations.selectServiceCategory),
                          items: [
                            for (final category in categories)
                              DropdownMenuItem(
                                value: category.id,
                                child: Text(
                                  category.localizedLongName(languageCode),
                                ),
                              ),
                          ],
                          validator: (value) => value == null
                              ? localizations.setupFieldRequired
                              : null,
                          onChanged: categoriesState.isLoading
                              ? null
                              : (value) => setState(() {
                                  _categoryId = value;
                                  _subcategoryIds.clear();
                                }),
                        ),
                        const SizedBox(height: AppSpacing.large),
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: localizations.serviceSubcategory,
                            helperText: localizations.selectServiceTypesHint,
                            prefixIcon: const Icon(
                              Icons.miscellaneous_services_outlined,
                            ),
                          ),
                          child: selectedCategory == null
                              ? Text(
                                  localizations.selectServiceCategoryFirst,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                              : Wrap(
                                  spacing: AppSpacing.small,
                                  runSpacing: AppSpacing.small,
                                  children: [
                                    for (final subcategory
                                        in selectedCategory.subcategories)
                                      FilterChip(
                                        key: ValueKey(
                                          'service-subcategory-${subcategory.id}',
                                        ),
                                        label: Text(
                                          subcategory.localizedName(
                                            languageCode,
                                          ),
                                        ),
                                        selected: _subcategoryIds.contains(
                                          subcategory.id,
                                        ),
                                        onSelected: (selected) => setState(() {
                                          if (selected) {
                                            _subcategoryIds.add(subcategory.id);
                                          } else {
                                            _subcategoryIds.remove(
                                              subcategory.id,
                                            );
                                          }
                                        }),
                                      ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: AppSpacing.large),
                        TextField(
                          key: const Key('service-description-field'),
                          controller: _professionController,
                          minLines: 2,
                          maxLines: 3,
                          maxLength: 160,
                          decoration: InputDecoration(
                            labelText: localizations.serviceDescription,
                            hintText: localizations.serviceDescriptionHint,
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.large),
                        DarJarInternationalPhoneField(
                          controller: _phoneController,
                          countryCode: _countryCode,
                          onCountryCodeChanged: (value) =>
                              setState(() => _countryCode = value),
                          phoneLabel: localizations.servicePhone,
                          countryCodeLabel: localizations.countryCode,
                          fieldKey: const Key('service-phone-field'),
                          countryCodeKey: const Key(
                            'service-country-code-field',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.large),
                        DarJarTextField(
                          key: const Key('service-neighborhood-field'),
                          controller: _neighborhoodController,
                          label: localizations.serviceNeighborhoodOptional,
                          hint: localizations.serviceNeighborhoodHint,
                          prefixIcon: Icons.location_on_outlined,
                        ),
                        if (_saving) ...[
                          const SizedBox(height: AppSpacing.large),
                          Text(
                            editing
                                ? localizations.updatingService
                                : localizations.savingService,
                          ),
                          const SizedBox(height: AppSpacing.small),
                          const LinearProgressIndicator(),
                        ],
                        const SizedBox(height: AppSpacing.xLarge),
                        if (compact)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SaveButton(
                                saving: _saving,
                                editing: editing,
                                onPressed: _save,
                              ),
                              const SizedBox(height: AppSpacing.small),
                              _CancelButton(
                                saving: _saving,
                                fallbackLocation: editing
                                    ? AppRoutes.directoryProfile(
                                        widget.entryId!,
                                      )
                                    : AppRoutes.directory,
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _CancelButton(
                                saving: _saving,
                                fallbackLocation: editing
                                    ? AppRoutes.directoryProfile(
                                        widget.entryId!,
                                      )
                                    : AppRoutes.directory,
                              ),
                              const SizedBox(width: AppSpacing.medium),
                              _SaveButton(
                                saving: _saving,
                                editing: editing,
                                onPressed: _save,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final localizations = AppLocalizations.of(context);
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final nationalNumber = digits.startsWith('0')
        ? digits.substring(1)
        : digits;
    final phone = '$_countryCode$nationalNumber';
    if (!(_formKey.currentState?.validate() ?? false) ||
        _categoryId == null ||
        _subcategoryIds.isEmpty ||
        _professionController.text.trim().length > 160 ||
        !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(phone)) {
      _showMessage(localizations.completeServiceFields);
      return;
    }

    setState(() => _saving = true);
    try {
      final controller = ref.read(directoryEntriesProvider.notifier);
      final id = widget.entryId;
      if (id == null) {
        final createdId = await controller.createService(
          name: _nameController.text,
          categoryId: _categoryId!,
          subcategoryIds: _subcategoryIds.toList(),
          profession: _professionController.text,
          phone: phone,
          neighborhood: _neighborhoodController.text,
        );
        if (!mounted) return;
        context.replace(AppRoutes.directoryProfile(createdId));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.serviceCreated)));
      } else {
        await controller.updateService(
          id: id,
          name: _nameController.text,
          categoryId: _categoryId!,
          subcategoryIds: _subcategoryIds.toList(),
          profession: _professionController.text,
          phone: phone,
          neighborhood: _neighborhoodController.text,
        );
        if (!mounted) return;
        context.replace(AppRoutes.directoryProfile(id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.serviceUpdated)));
      }
    } on DirectoryFailure {
      if (mounted) {
        _showMessage(
          widget.entryId == null
              ? localizations.serviceCreateFailed
              : localizations.serviceUpdateFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _populateFrom(DirectoryEntry entry) {
    _initializedFromEntry = true;
    _nameController.text = entry.name;
    _professionController.text = entry.profession;
    _neighborhoodController.text = entry.neighborhood;
    _categoryId = entry.categoryId;
    _subcategoryIds
      ..clear()
      ..addAll(entry.subcategoryIds);
    final phoneParts = splitInternationalPhoneNumber(entry.phone);
    _countryCode = phoneParts.countryCode;
    _phoneController.text = phoneParts.nationalNumber;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.saving,
    required this.editing,
    required this.onPressed,
  });

  final bool saving;
  final bool editing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DarJarButton(
      key: const Key('save-service-button'),
      label: editing
          ? AppLocalizations.of(context).updateService
          : AppLocalizations.of(context).saveService,
      icon: editing ? Icons.save_outlined : Icons.add_rounded,
      onPressed: saving ? null : onPressed,
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.saving, required this.fallbackLocation});

  final bool saving;
  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    return DarJarButton(
      label: AppLocalizations.of(context).cancel,
      variant: DarJarButtonVariant.secondary,
      onPressed: saving
          ? null
          : () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(fallbackLocation);
              }
            },
    );
  }
}

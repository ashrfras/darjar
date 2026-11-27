import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_international_phone_field.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_phone_number.dart';
import 'package:darjar/core/widgets/darjar_setup_scaffold.dart';
import 'package:darjar/features/directory/data/professional_profile_repository.dart';
import 'package:darjar/features/directory/presentation/professional_enrollment.dart';
import 'package:darjar/features/residence/presentation/darjar_city_picker.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/core/utils/phone_number.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:darjar/features/directory/data/service_categories_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateServicePage extends ConsumerStatefulWidget {
  const CreateServicePage({this.entryId, this.professional = false, super.key});

  final String? entryId;
  final bool professional;

  @override
  ConsumerState<CreateServicePage> createState() => _CreateServicePageState();
}

class _CreateServicePageState extends ConsumerState<CreateServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _professionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String? _city;
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final editing = widget.entryId != null;
    final professional = widget.professional;
    final onboarding = professional && !editing;
    final currentUser = ref.watch(authRepositoryProvider).currentUser;
    final existing = professional && editing
        ? ref.watch(professionalEntryProvider(widget.entryId!))
        : null;
    final profile = professional && !editing && currentUser != null
        ? ref.watch(professionalAccountProfileProvider(currentUser))
        : null;
    DirectoryEntry? entry;
    if (editing) {
      if (professional) {
        entry = existing?.value;
      } else {
        ref.watch(directoryEntriesProvider);
        entry = ref
            .read(directoryEntriesProvider.notifier)
            .find(widget.entryId!);
      }
      if (entry != null && !_initializedFromEntry) _populateFrom(entry);
    }
    final lockedPhone =
        professional || entry?.isOwnedBy(currentUser?.uid) == true;
    final fallback = professional
        ? (editing ? AppRoutes.professional : AppRoutes.residenceSetup)
        : (editing
              ? AppRoutes.directoryProfile(widget.entryId!)
              : AppRoutes.directory);
    if (existing?.isLoading == true || profile?.isLoading == true) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (profile?.hasError == true) {
      return Scaffold(
        body: Center(
          child: DarJarButton(
            label: localizations.accountResolutionRetry,
            onPressed: () => ref.invalidate(
              professionalAccountProfileProvider(currentUser!),
            ),
          ),
        ),
      );
    }
    final categoriesState = ref.watch(serviceCategoriesProvider);
    final categories = categoriesState.value ?? const <ServiceCategory>[];
    final languageCode = Localizations.localeOf(context).languageCode;
    final selectedCategory = categories
        .where((category) => category.id == _categoryId)
        .firstOrNull;
    final compact = MediaQuery.sizeOf(context).width < 600;

    if (editing &&
        (entry == null ||
            (professional
                ? !entry.isOwnedBy(currentUser?.uid)
                : !entry.canEdit(currentUser?.uid)))) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.xLarge),
          children: [
            DarJarSubpageHeader(fallbackLocation: fallback),
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
        padding: onboarding
            ? const EdgeInsets.all(AppSpacing.xLarge)
            : EdgeInsets.fromLTRB(
                compact ? 12 : AppSpacing.xLarge,
                compact ? 16 : AppSpacing.xLarge,
                compact ? 12 : AppSpacing.xLarge,
                AppSpacing.xxLarge,
              ),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: onboarding ? 640 : 780),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (onboarding) ...[
                  DarJarSetupIntroduction(
                    icon: Icons.badge_outlined,
                    title: localizations.professionalCreateTitle,
                    description: localizations.professionalOptionDescription,
                  ),
                  const SizedBox(height: AppSpacing.xLarge),
                ] else ...[
                  DarJarSubpageHeader(
                    title: editing
                        ? localizations.editService
                        : localizations.createService,
                    fallbackLocation: fallback,
                  ),
                  const SizedBox(height: AppSpacing.xLarge),
                  Text(
                    editing
                        ? localizations.editServiceDescription
                        : localizations.createServiceDescription,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.large),
                ],
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
                        if (professional) ...[
                          DarJarCityPickerField(
                            value: _city,
                            enabled: !_saving,
                            validator: (value) => value == null
                                ? localizations.setupFieldRequired
                                : null,
                            onChanged: (value) => setState(() => _city = value),
                          ),
                          const SizedBox(height: AppSpacing.large),
                        ],
                        if (lockedPhone)
                          InputDecorator(
                            decoration: InputDecoration(
                              labelText:
                                  localizations.professionalVerifiedContact,
                            ),
                            child: DarJarPhoneNumber(
                              entry?.phone ?? currentUser?.phoneNumber ?? '',
                            ),
                          )
                        else
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
                        if (professional &&
                            !editing &&
                            profile?.hasValue == true &&
                            profile?.value == null)
                          ProfessionalPersonalNameFields(
                            firstName: _firstNameController,
                            lastName: _lastNameController,
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
                                onPressed: () => _save(
                                  professionalEntry: entry,
                                  needsName:
                                      profile?.hasValue == true &&
                                      profile?.value == null,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.small),
                              _CancelButton(
                                saving: _saving,
                                fallbackLocation: fallback,
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _CancelButton(
                                saving: _saving,
                                fallbackLocation: fallback,
                              ),
                              const SizedBox(width: AppSpacing.medium),
                              _SaveButton(
                                saving: _saving,
                                editing: editing,
                                onPressed: () => _save(
                                  professionalEntry: entry,
                                  needsName:
                                      profile?.hasValue == true &&
                                      profile?.value == null,
                                ),
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

  Future<void> _save({
    required DirectoryEntry? professionalEntry,
    required bool needsName,
  }) async {
    final localizations = AppLocalizations.of(context);
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final nationalNumber = digits.startsWith('0')
        ? digits.substring(1)
        : digits;
    final phone = '$_countryCode$nationalNumber';
    final user = ref.read(authRepositoryProvider).currentUser;
    final id = widget.entryId;
    final lockedPhone =
        widget.professional || professionalEntry?.isOwnedBy(user?.uid) == true;
    final name = (
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );
    if (needsName && (name.firstName.isEmpty || name.lastName.isEmpty)) {
      _showMessage(localizations.accountResolutionMissingProfile);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false) ||
        _categoryId == null ||
        _subcategoryIds.isEmpty ||
        _professionController.text.trim().length > 160 ||
        (!lockedPhone && !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(phone))) {
      _showMessage(localizations.completeServiceFields);
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.professional) {
        if (user == null) throw const DirectoryFailure('missing-user');
        final city = _city!;
        if (id == null) {
          await ref.read(professionalProfileRepositoryProvider).create(user, (
            name: _nameController.text,
            categoryId: _categoryId!,
            subcategoryIds: _subcategoryIds.toList(),
            profession: _professionController.text,
            neighborhood: _neighborhoodController.text,
            city: city,
          ), needsName ? name : null);
        } else {
          await ref
              .read(directoryRepositoryProvider)
              .updateService(
                serviceId: id,
                userId: user.uid,
                name: _nameController.text,
                categoryId: _categoryId!,
                subcategoryIds: _subcategoryIds.toList(),
                profession: _professionController.text,
                phone: professionalEntry!.phone,
                neighborhood: _neighborhoodController.text,
                city: city,
              );
        }
        if (!mounted ||
            ref.read(authRepositoryProvider).currentUser?.uid != user.uid) {
          return;
        }
        if (id == null) {
          refreshProfessionalSpace(
            ProviderScope.containerOf(context, listen: false),
            user,
          );
        }
        context.go(AppRoutes.professional);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              id == null
                  ? localizations.serviceCreated
                  : localizations.serviceUpdated,
            ),
          ),
        );
        return;
      }
      final controller = ref.read(directoryEntriesProvider.notifier);
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
          phone: lockedPhone ? professionalEntry!.phone : phone,
          neighborhood: _neighborhoodController.text,
        );
        if (!mounted) return;
        context.replace(AppRoutes.directoryProfile(id));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.serviceUpdated)));
      }
    } on DirectoryFailure catch (error) {
      if (mounted &&
          widget.professional &&
          id == null &&
          [
            'directory-phone-exists',
            'already-owns-service',
          ].contains(error.code)) {
        ref.invalidate(residenceContextProvider);
        _showMessage(localizations.professionalPhoneInUse);
        context.replace(AppRoutes.startProfessional);
      } else if (mounted) {
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
    _city = entry.city.isEmpty ? null : entry.city;
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

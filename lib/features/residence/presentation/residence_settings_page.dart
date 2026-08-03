import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/images/app_image_picker.dart';
import 'package:darjar/core/images/storage_image_provider.dart';
import 'package:darjar/core/utils/phone_number.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_international_phone_field.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:darjar/features/residence/data/residence_image_repository.dart';
import 'package:darjar/features/residence/data/residence_settings_repository.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/residence/presentation/darjar_city_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ResidenceSettingsPage extends ConsumerWidget {
  const ResidenceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(residenceSettingsProvider);
    return settings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: DarJarButton(
          label: AppLocalizations.of(context).accountResolutionRetry,
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(residenceSettingsProvider),
        ),
      ),
      data: (data) => _ResidenceSettingsForm(
        key: ValueKey(data.residenceId),
        settings: data,
      ),
    );
  }
}

class _ResidenceSettingsForm extends ConsumerStatefulWidget {
  const _ResidenceSettingsForm({required this.settings, super.key});

  final ResidenceSettings settings;

  @override
  ConsumerState<_ResidenceSettingsForm> createState() =>
      _ResidenceSettingsFormState();
}

class _ResidenceSettingsFormState
    extends ConsumerState<_ResidenceSettingsForm> {
  late final TextEditingController _joinCodeController;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _yearController;
  late final TextEditingController _amountController;
  late final TextEditingController _managementOrganizationController;
  late final TextEditingController _managementPhoneController;
  late String _managementCountryCode;
  late final TextEditingController _bankNameController;
  late final TextEditingController _bankAccountController;
  late ResidenceSettings _savedSettings;
  late String _selectedCity;
  late bool _hasImage;
  Uint8List? _selectedImageBytes;
  bool _imageChanged = false;
  bool _processingImage = false;
  late List<ResidenceBuildingConfiguration> _buildings;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    final settings = widget.settings;
    _savedSettings = settings;
    _joinCodeController = TextEditingController(text: settings.joinCode);
    _nameController = TextEditingController(text: settings.name);
    _addressController = TextEditingController(text: settings.address);
    _yearController = TextEditingController(
      text: settings.establishmentYear.toString(),
    );
    _amountController = TextEditingController(
      text: settings.defaultSubscriptionAmount.toString(),
    );
    _managementOrganizationController = TextEditingController(
      text: settings.managementOrganization,
    );
    final managementPhone = splitInternationalPhoneNumber(
      settings.managementPhone,
    );
    _managementCountryCode = managementPhone.countryCode;
    _managementPhoneController = TextEditingController(
      text: managementPhone.nationalNumber,
    );
    _bankNameController = TextEditingController(text: settings.bankName);
    _bankAccountController = TextEditingController(text: settings.bankAccount);
    _selectedCity = settings.city;
    _hasImage = settings.hasImage;
    _buildings = List.of(settings.buildings);
    for (final controller in _editableControllers) {
      controller.addListener(_updateDirty);
    }
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _yearController.dispose();
    _amountController.dispose();
    _managementOrganizationController.dispose();
    _managementPhoneController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;

    return PopScope<Object?>(
      canPop: !_isDirty || _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmLeaving();
      },
      child: Stack(
        key: const Key('residence-settings-page'),
        children: [
          SingleChildScrollView(
            key: const Key('residence-settings-scroll-view'),
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : AppSpacing.xLarge,
              compact ? AppSpacing.small : AppSpacing.xLarge,
              compact ? 12 : AppSpacing.xLarge,
              112,
            ),
            child: Align(
              alignment: AlignmentDirectional.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DarJarSubpageHeader(
                      title: localizations.residenceSettings,
                      description: compact
                          ? null
                          : localizations.residenceSettingsPageDescription,
                      fallbackLocation: AppRoutes.profile,
                      onBack: _requestBack,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 760) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ResidenceInformationSection(
                                residenceId: widget.settings.residenceId,
                                residenceIdController: _joinCodeController,
                                nameController: _nameController,
                                addressController: _addressController,
                                selectedCity: _selectedCity,
                                onCityChanged: _setCity,
                                yearController: _yearController,
                                hasImage: _hasImage,
                                selectedImageBytes: _selectedImageBytes,
                                processingImage: _processingImage,
                                onSelectImage: _selectImage,
                                onRemoveImage: _removeImage,
                              ),
                              const SizedBox(height: AppSpacing.large),
                              _ManagementInformationSection(
                                organizationController:
                                    _managementOrganizationController,
                                phoneController: _managementPhoneController,
                                countryCode: _managementCountryCode,
                                onCountryCodeChanged: _setManagementCountryCode,
                                bankNameController: _bankNameController,
                                bankAccountController: _bankAccountController,
                              ),
                              const SizedBox(height: AppSpacing.large),
                              _ResidenceStructureSection(
                                buildings: _buildings,
                                onAddBuilding: () => _showBuildingDialog(),
                                onEditBuilding: (building) =>
                                    _showBuildingDialog(building: building),
                                onDeleteBuilding: _deleteBuilding,
                              ),
                              const SizedBox(height: AppSpacing.large),
                              _SubscriptionSection(
                                amountController: _amountController,
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      _ResidenceInformationSection(
                                        residenceId:
                                            widget.settings.residenceId,
                                        residenceIdController:
                                            _joinCodeController,
                                        nameController: _nameController,
                                        addressController: _addressController,
                                        selectedCity: _selectedCity,
                                        onCityChanged: _setCity,
                                        yearController: _yearController,
                                        hasImage: _hasImage,
                                        selectedImageBytes: _selectedImageBytes,
                                        processingImage: _processingImage,
                                        onSelectImage: _selectImage,
                                        onRemoveImage: _removeImage,
                                      ),
                                      const SizedBox(height: AppSpacing.large),
                                      _ManagementInformationSection(
                                        organizationController:
                                            _managementOrganizationController,
                                        phoneController:
                                            _managementPhoneController,
                                        countryCode: _managementCountryCode,
                                        onCountryCodeChanged:
                                            _setManagementCountryCode,
                                        bankNameController: _bankNameController,
                                        bankAccountController:
                                            _bankAccountController,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.large),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _ResidenceStructureSection(
                                        buildings: _buildings,
                                        onAddBuilding: () =>
                                            _showBuildingDialog(),
                                        onEditBuilding: (building) =>
                                            _showBuildingDialog(
                                              building: building,
                                            ),
                                        onDeleteBuilding: _deleteBuilding,
                                      ),
                                      const SizedBox(height: AppSpacing.large),
                                      _SubscriptionSection(
                                        amountController: _amountController,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: _StickySaveBar(
              onSave: _isDirty && !_isSaving ? () => _save() : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectImage() async {
    if (_processingImage) return;
    setState(() => _processingImage = true);
    try {
      final selection = await pickAndCompressAppImage();
      if (selection == null || !mounted) return;
      setState(() {
        _selectedImageBytes = selection.bytes;
        _hasImage = true;
        _imageChanged = true;
        _isDirty = _hasChanges;
      });
    } catch (_) {
      if (mounted) {
        _showMessage(AppLocalizations.of(context).imageProcessingFailed);
      }
    } finally {
      if (mounted) setState(() => _processingImage = false);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _hasImage = false;
      _imageChanged = true;
      _isDirty = _hasChanges;
    });
  }

  void _setCity(String? city) {
    if (city == null || city == _selectedCity) return;
    setState(() {
      _selectedCity = city;
      _isDirty = _hasChanges;
    });
  }

  void _setManagementCountryCode(String countryCode) {
    if (countryCode == _managementCountryCode) return;
    setState(() {
      _managementCountryCode = countryCode;
      _isDirty = _hasChanges;
    });
  }

  Future<void> _showBuildingDialog({
    ResidenceBuildingConfiguration? building,
  }) async {
    final result = await showDialog<({String name, int floorCount})>(
      context: context,
      builder: (context) => _BuildingEditorDialog(building: building),
    );
    if (!mounted || result == null) return;

    setState(() {
      if (building == null) {
        _buildings = [
          ..._buildings,
          ResidenceBuildingConfiguration(
            id: 'building-${DateTime.now().microsecondsSinceEpoch}',
            name: result.name,
            floorCount: result.floorCount,
          ),
        ];
      } else {
        _buildings = [
          for (final item in _buildings)
            if (item.id == building.id)
              item.copyWith(name: result.name, floorCount: result.floorCount)
            else
              item,
        ];
      }
      _isDirty = _hasChanges;
    });
  }

  Future<void> _deleteBuilding(ResidenceBuildingConfiguration building) async {
    final localizations = AppLocalizations.of(context);
    if (_buildings.length == 1) {
      _showMessage(localizations.atLeastOneBuilding);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('delete-building-dialog'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(localizations.deleteBuilding),
        content: Text(localizations.confirmDeleteBuilding(building.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            key: const Key('confirm-delete-building-button'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _buildings = _buildings
          .where((item) => item.id != building.id)
          .toList(growable: false);
      _isDirty = _hasChanges;
    });
  }

  Future<bool> _save() async {
    final localizations = AppLocalizations.of(context);
    final amount = int.tryParse(_amountController.text.trim());
    final establishmentYear = int.tryParse(_yearController.text.trim());
    if (_nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _selectedCity.isEmpty ||
        _buildings.isEmpty ||
        establishmentYear == null ||
        establishmentYear < 1800 ||
        establishmentYear > DateTime.now().year ||
        amount == null ||
        amount < 0) {
      _showMessage(localizations.checkResidenceSettingsFields);
      return false;
    }

    final updatedSettings = _savedSettings.copyWith(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      city: _selectedCity,
      establishmentYear: establishmentYear,
      defaultSubscriptionAmount: amount,
      hasImage: _hasImage,
      buildings: _buildings,
      managementOrganization: _managementOrganizationController.text.trim(),
      managementPhone: formatInternationalPhoneNumber(
        _managementCountryCode,
        _managementPhoneController.text,
      ),
      bankName: _bankNameController.text.trim(),
      bankAccount: _bankAccountController.text.trim(),
    );
    setState(() => _isSaving = true);
    try {
      if (_imageChanged) {
        if (_hasImage && _selectedImageBytes != null) {
          final user = ref.read(authRepositoryProvider).currentUser;
          if (user == null) {
            throw const ResidenceSettingsFailure('signed-out');
          }
          await ref
              .read(residenceImageRepositoryProvider)
              .upload(
                residenceId: updatedSettings.residenceId,
                userId: user.uid,
                bytes: _selectedImageBytes!,
              );
        } else if (!_hasImage) {
          await ref
              .read(residenceImageRepositoryProvider)
              .remove(updatedSettings.residenceId);
        }
        ref.invalidate(storageImageBytesProvider);
      }
      await ref.read(residenceSettingsProvider.notifier).save(updatedSettings);
      ref.invalidate(residenceMembersProvider);
      if (mounted) {
        setState(() {
          _savedSettings = updatedSettings;
          _selectedImageBytes = null;
          _imageChanged = false;
          _isDirty = false;
          _isSaving = false;
        });
        _showMessage(localizations.residenceSettingsSaved);
      }
      return true;
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showMessage(
          error is ResidenceSettingsFailure &&
                  error.code == 'structure-not-empty'
              ? localizations.structureContainsApartments
              : _imageChanged
              ? localizations.imageUploadFailed
              : localizations.setupUnexpectedError,
        );
      }
      return false;
    }
  }

  List<TextEditingController> get _editableControllers => [
    _nameController,
    _addressController,
    _yearController,
    _amountController,
    _managementOrganizationController,
    _managementPhoneController,
    _bankNameController,
    _bankAccountController,
  ];

  void _updateDirty() {
    final dirty = _hasChanges;
    if (dirty != _isDirty && mounted) {
      setState(() => _isDirty = dirty);
    }
  }

  bool get _hasChanges {
    return _nameController.text.trim() != _savedSettings.name ||
        _addressController.text.trim() != _savedSettings.address ||
        _selectedCity != _savedSettings.city ||
        _yearController.text.trim() !=
            _savedSettings.establishmentYear.toString() ||
        _amountController.text.trim() !=
            _savedSettings.defaultSubscriptionAmount.toString() ||
        _managementOrganizationController.text.trim() !=
            _savedSettings.managementOrganization ||
        normalizePhoneNumber(
              formatInternationalPhoneNumber(
                _managementCountryCode,
                _managementPhoneController.text,
              ),
            ) !=
            normalizePhoneNumber(_savedSettings.managementPhone) ||
        _bankNameController.text.trim() != _savedSettings.bankName ||
        _bankAccountController.text.trim() != _savedSettings.bankAccount ||
        _hasImage != _savedSettings.hasImage ||
        _imageChanged ||
        !_sameBuildings(_buildings, _savedSettings.buildings);
  }

  bool _sameBuildings(
    List<ResidenceBuildingConfiguration> first,
    List<ResidenceBuildingConfiguration> second,
  ) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index].id != second[index].id ||
          first[index].name != second[index].name ||
          first[index].floorCount != second[index].floorCount) {
        return false;
      }
    }
    return true;
  }

  Future<void> _confirmLeaving() async {
    if (!_isDirty || _isSaving) return;
    final localizations = AppLocalizations.of(context);
    final action = await showDialog<_UnsavedChangesAction>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('unsaved-residence-settings-dialog'),
        title: Text(localizations.unsavedChangesTitle),
        content: Text(localizations.unsavedChangesDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          TextButton(
            key: const Key('discard-residence-settings-button'),
            onPressed: () =>
                Navigator.pop(context, _UnsavedChangesAction.discard),
            child: Text(localizations.discardChanges),
          ),
          FilledButton(
            key: const Key('save-before-leaving-button'),
            onPressed: () => Navigator.pop(context, _UnsavedChangesAction.save),
            child: Text(localizations.saveChanges),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == _UnsavedChangesAction.save && !await _save()) return;
    _leaveSettings();
  }

  void _requestBack() {
    if (_isDirty) {
      _confirmLeaving();
    } else {
      _leaveSettings();
    }
  }

  void _leaveSettings() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.profile);
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BuildingEditorDialog extends StatefulWidget {
  const _BuildingEditorDialog({this.building});

  final ResidenceBuildingConfiguration? building;

  @override
  State<_BuildingEditorDialog> createState() => _BuildingEditorDialogState();
}

enum _UnsavedChangesAction { discard, save }

class _BuildingEditorDialogState extends State<_BuildingEditorDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.building?.name,
  );
  late final TextEditingController _floorsController = TextEditingController(
    text: widget.building?.floorCount.toString() ?? '1',
  );
  bool _showError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _floorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AlertDialog(
      key: const Key('building-editor-dialog'),
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(
        widget.building == null
            ? localizations.addBuilding
            : localizations.editBuilding,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DarJarTextField(
                key: const Key('building-name-field'),
                controller: _nameController,
                label: localizations.buildingName,
                hint: localizations.buildingNameHint,
                prefixIcon: Icons.apartment_outlined,
              ),
              const SizedBox(height: AppSpacing.large),
              DarJarTextField(
                key: const Key('building-floor-count-field'),
                controller: _floorsController,
                label: localizations.floorCount,
                prefixIcon: Icons.layers_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              if (_showError) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  localizations.checkBuildingFields,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localizations.cancel),
        ),
        FilledButton(
          key: const Key('confirm-building-button'),
          onPressed: _submit,
          child: Text(localizations.saveChanges),
        ),
      ],
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final floorCount = int.tryParse(_floorsController.text.trim());
    if (name.isEmpty || floorCount == null || floorCount < 1) {
      setState(() => _showError = true);
      return;
    }
    Navigator.pop(context, (name: name, floorCount: floorCount));
  }
}

class _ResidenceInformationSection extends ConsumerWidget {
  const _ResidenceInformationSection({
    required this.residenceId,
    required this.residenceIdController,
    required this.nameController,
    required this.addressController,
    required this.selectedCity,
    required this.onCityChanged,
    required this.yearController,
    required this.hasImage,
    required this.selectedImageBytes,
    required this.processingImage,
    required this.onSelectImage,
    required this.onRemoveImage,
  });

  final String residenceId;
  final TextEditingController residenceIdController;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final String selectedCity;
  final ValueChanged<String?> onCityChanged;
  final TextEditingController yearController;
  final bool hasImage;
  final Uint8List? selectedImageBytes;
  final bool processingImage;
  final VoidCallback onSelectImage;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    return _SettingsSection(
      key: const Key('residence-information-section'),
      icon: Icons.domain_outlined,
      title: localizations.residenceInformation,
      description: localizations.residenceInformationDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                key: const Key('residence-image-preview'),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: hasImage ? AppColors.primary : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                alignment: Alignment.center,
                child: selectedImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        child: Image.memory(
                          selectedImageBytes!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      )
                    : hasImage
                    ? ref
                          .watch(
                            storageImageBytesProvider(
                              residenceImageStoragePath(residenceId),
                            ),
                          )
                          .when(
                            data: (bytes) => ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadius.large,
                              ),
                              child: Image.memory(
                                bytes,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                            loading: () =>
                                const CircularProgressIndicator(strokeWidth: 2),
                            error: (_, _) => const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.primary,
                            ),
                          )
                    : const Icon(
                        Icons.apartment_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.residenceImage,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      localizations.squareImageRecommended,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Wrap(
                      spacing: AppSpacing.xSmall,
                      children: [
                        DarJarButton(
                          key: const Key('select-residence-image-button'),
                          label: hasImage
                              ? localizations.changeImage
                              : localizations.addImage,
                          icon: Icons.add_photo_alternate_outlined,
                          variant: DarJarButtonVariant.tertiary,
                          onPressed: processingImage ? null : onSelectImage,
                        ),
                        if (hasImage)
                          DarJarButton(
                            key: const Key('remove-residence-image-button'),
                            label: localizations.removeImage,
                            icon: Icons.delete_outline_rounded,
                            variant: DarJarButtonVariant.tertiary,
                            onPressed: processingImage ? null : onRemoveImage,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Text(
            localizations.residenceId,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  key: const Key('residence-id-field'),
                  readOnly: true,
                  label: localizations.residenceId,
                  value: residenceIdController.text,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.medium,
                      vertical: AppSpacing.small,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      border: Border.all(color: AppColors.outline),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.numbers_rounded,
                          color: AppColors.inkMuted,
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: Text(
                            residenceIdController.text,
                            key: const Key('residence-id-value'),
                            textDirection: TextDirection.rtl,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.inkMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  key: const Key('copy-residence-id-button'),
                  onPressed: () => _copyResidenceId(context),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(localizations.copy),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          DarJarTextField(
            key: const Key('residence-name-field'),
            controller: nameController,
            label: localizations.residenceName,
            prefixIcon: Icons.apartment_outlined,
          ),
          const SizedBox(height: AppSpacing.large),
          DarJarTextField(
            key: const Key('residence-address-field'),
            controller: addressController,
            label: localizations.address,
            prefixIcon: Icons.location_on_outlined,
          ),
          const SizedBox(height: AppSpacing.large),
          DarJarCityPickerField(
            key: const Key('settings-residence-city-field'),
            value: selectedCity,
            onChanged: onCityChanged,
          ),
          const SizedBox(height: AppSpacing.large),
          DarJarTextField(
            key: const Key('establishment-year-field'),
            controller: yearController,
            label: localizations.establishmentYear,
            prefixIcon: Icons.calendar_today_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyResidenceId(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: residenceIdController.text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(localizations.residenceIdCopied)));
  }
}

class _ManagementInformationSection extends StatelessWidget {
  const _ManagementInformationSection({
    required this.organizationController,
    required this.phoneController,
    required this.countryCode,
    required this.onCountryCodeChanged,
    required this.bankNameController,
    required this.bankAccountController,
  });

  final TextEditingController organizationController;
  final TextEditingController phoneController;
  final String countryCode;
  final ValueChanged<String> onCountryCodeChanged;
  final TextEditingController bankNameController;
  final TextEditingController bankAccountController;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return _SettingsSection(
      key: const Key('management-information-section'),
      icon: Icons.business_outlined,
      title: localizations.managementInformation,
      description: localizations.managementSettingsDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DarJarTextField(
            key: const Key('management-organization-field'),
            controller: organizationController,
            label: localizations.managementCompany,
            prefixIcon: Icons.business_center_outlined,
          ),
          const SizedBox(height: AppSpacing.large),
          DarJarInternationalPhoneField(
            key: const Key('management-phone-field'),
            fieldKey: const Key('management-phone-number-field'),
            countryCodeKey: const Key('management-phone-country-code-field'),
            controller: phoneController,
            countryCode: countryCode,
            onCountryCodeChanged: onCountryCodeChanged,
            phoneLabel: localizations.phone,
            countryCodeLabel: localizations.countryCode,
          ),
          const SizedBox(height: AppSpacing.large),
          DarJarTextField(
            key: const Key('management-bank-name-field'),
            controller: bankNameController,
            label: localizations.bankName,
            prefixIcon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: AppSpacing.large),
          DarJarTextField(
            key: const Key('management-bank-account-field'),
            controller: bankAccountController,
            label: localizations.bankAccount,
            prefixIcon: Icons.numbers_rounded,
          ),
        ],
      ),
    );
  }
}

class _ResidenceStructureSection extends StatelessWidget {
  const _ResidenceStructureSection({
    required this.buildings,
    required this.onAddBuilding,
    required this.onEditBuilding,
    required this.onDeleteBuilding,
  });

  final List<ResidenceBuildingConfiguration> buildings;
  final VoidCallback onAddBuilding;
  final ValueChanged<ResidenceBuildingConfiguration> onEditBuilding;
  final ValueChanged<ResidenceBuildingConfiguration> onDeleteBuilding;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return _SettingsSection(
      key: const Key('residence-structure-section'),
      icon: Icons.account_tree_outlined,
      title: localizations.residenceStructure,
      description: localizations.residenceStructureDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < buildings.length; index++) ...[
            _BuildingConfigurationTile(
              key: ValueKey('residence-building-${buildings[index].id}'),
              building: buildings[index],
              onEdit: () => onEditBuilding(buildings[index]),
              onDelete: () => onDeleteBuilding(buildings[index]),
            ),
            if (index < buildings.length - 1)
              const SizedBox(height: AppSpacing.small),
          ],
          const SizedBox(height: AppSpacing.medium),
          DarJarButton(
            key: const Key('add-building-button'),
            label: localizations.addBuilding,
            icon: Icons.add_rounded,
            variant: DarJarButtonVariant.secondary,
            expanded: true,
            onPressed: onAddBuilding,
          ),
        ],
      ),
    );
  }
}

class _BuildingConfigurationTile extends StatelessWidget {
  const _BuildingConfigurationTile({
    required this.building,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final ResidenceBuildingConfiguration building;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Material(
      color: AppColors.surface,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.apartment_outlined, color: AppColors.primary),
        title: Text(building.name),
        subtitle: Text(localizations.buildingFloorCount(building.floorCount)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: ValueKey('edit-building-${building.id}'),
              tooltip: localizations.editBuilding,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            IconButton(
              key: ValueKey('delete-building-${building.id}'),
              tooltip: localizations.deleteBuilding,
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionSection extends StatelessWidget {
  const _SubscriptionSection({required this.amountController});

  final TextEditingController amountController;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return _SettingsSection(
      key: const Key('residence-subscription-section'),
      icon: Icons.receipt_long_outlined,
      title: localizations.subscription,
      description: localizations.subscriptionDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  localizations.defaultSubscription,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.small,
                  vertical: AppSpacing.xSmall,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  localizations.monthly,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          DarJarTextField(
            key: const Key('default-subscription-amount-field'),
            controller: amountController,
            label: localizations.amount,
            prefixIcon: Icons.payments_outlined,
            suffixText: localizations.currency,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }
}

class _StickySaveBar extends StatelessWidget {
  const _StickySaveBar({required this.onSave});

  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Material(
      key: const Key('sticky-save-bar'),
      color: AppColors.surface,
      elevation: 10,
      shadowColor: AppColors.ink.withValues(alpha: 0.14),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : AppSpacing.xLarge,
          vertical: AppSpacing.medium,
        ),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.outline)),
        ),
        child: Align(
          alignment: AlignmentDirectional.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: DarJarButton(
                key: const Key('save-residence-settings-button'),
                label: localizations.saveChanges,
                icon: Icons.check_rounded,
                expanded: compact,
                onPressed: onSave,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          child,
        ],
      ),
    );
  }
}

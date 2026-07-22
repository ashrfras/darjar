import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/residence/data/residence_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ResidenceSettingsPage extends ConsumerStatefulWidget {
  const ResidenceSettingsPage({super.key});

  @override
  ConsumerState<ResidenceSettingsPage> createState() =>
      _ResidenceSettingsPageState();
}

class _ResidenceSettingsPageState extends ConsumerState<ResidenceSettingsPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _yearController;
  late final TextEditingController _amountController;
  late final TextEditingController _managementOrganizationController;
  late final TextEditingController _managementPhoneController;
  late final TextEditingController _managementOfficeHoursController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _bankAccountController;
  late bool _hasImage;
  late bool _joinRequestsEnabled;
  late List<ResidenceBuildingConfiguration> _buildings;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(residenceSettingsProvider);
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
    _managementPhoneController = TextEditingController(
      text: settings.managementPhone,
    );
    _managementOfficeHoursController = TextEditingController(
      text: settings.managementOfficeHours,
    );
    _bankNameController = TextEditingController(text: settings.bankName);
    _bankAccountController = TextEditingController(text: settings.bankAccount);
    _hasImage = settings.hasImage;
    _joinRequestsEnabled = settings.joinRequestsEnabled;
    _buildings = List.of(settings.buildings);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _yearController.dispose();
    _amountController.dispose();
    _managementOrganizationController.dispose();
    _managementPhoneController.dispose();
    _managementOfficeHoursController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final settings = ref.watch(residenceSettingsProvider);
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Stack(
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
                  ),
                  const SizedBox(height: AppSpacing.large),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 760) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ResidenceInformationSection(
                              nameController: _nameController,
                              addressController: _addressController,
                              yearController: _yearController,
                              hasImage: _hasImage,
                              onToggleImage: _toggleImage,
                            ),
                            const SizedBox(height: AppSpacing.large),
                            _ManagementInformationSection(
                              organizationController:
                                  _managementOrganizationController,
                              phoneController: _managementPhoneController,
                              officeHoursController:
                                  _managementOfficeHoursController,
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
                            const SizedBox(height: AppSpacing.large),
                            _JoiningSection(
                              settings: settings,
                              joinRequestsEnabled: _joinRequestsEnabled,
                              onCopy: _copyInvitationLink,
                              onShowQr: _showQrCodeDialog,
                              onToggleRequests: (enabled) {
                                setState(() => _joinRequestsEnabled = enabled);
                              },
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
                                      nameController: _nameController,
                                      addressController: _addressController,
                                      yearController: _yearController,
                                      hasImage: _hasImage,
                                      onToggleImage: _toggleImage,
                                    ),
                                    const SizedBox(height: AppSpacing.large),
                                    _ManagementInformationSection(
                                      organizationController:
                                          _managementOrganizationController,
                                      phoneController:
                                          _managementPhoneController,
                                      officeHoursController:
                                          _managementOfficeHoursController,
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
                          const SizedBox(height: AppSpacing.large),
                          _JoiningSection(
                            settings: settings,
                            joinRequestsEnabled: _joinRequestsEnabled,
                            onCopy: _copyInvitationLink,
                            onShowQr: _showQrCodeDialog,
                            onToggleRequests: (enabled) {
                              setState(() => _joinRequestsEnabled = enabled);
                            },
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
          child: _StickySaveBar(onSave: _save),
        ),
      ],
    );
  }

  void _toggleImage() {
    setState(() => _hasImage = !_hasImage);
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
    });
  }

  Future<void> _showQrCodeDialog() async {
    final localizations = AppLocalizations.of(context);
    final url = ref.read(residenceSettingsProvider).invitationUrl;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('invitation-qr-dialog'),
        title: Text(localizations.invitationQrCode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              key: const Key('invitation-qr-code'),
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.outline),
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: SizedBox.square(
                dimension: 220,
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 220,
                  padding: EdgeInsets.zero,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.ink,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              localizations.scanToJoin,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('close-qr-dialog-button'),
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }

  Future<void> _copyInvitationLink() async {
    final localizations = AppLocalizations.of(context);
    final url = ref.read(residenceSettingsProvider).invitationUrl;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    _showMessage(localizations.invitationLinkCopied);
  }

  void _save() {
    final localizations = AppLocalizations.of(context);
    final amount = int.tryParse(_amountController.text.trim());
    final establishmentYear = int.tryParse(_yearController.text.trim());
    if (_nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _managementOrganizationController.text.trim().isEmpty ||
        _managementPhoneController.text.trim().isEmpty ||
        _managementOfficeHoursController.text.trim().isEmpty ||
        _bankNameController.text.trim().isEmpty ||
        _bankAccountController.text.trim().isEmpty ||
        establishmentYear == null ||
        establishmentYear < 1800 ||
        establishmentYear > DateTime.now().year ||
        amount == null ||
        amount < 0) {
      _showMessage(localizations.checkResidenceSettingsFields);
      return;
    }

    final current = ref.read(residenceSettingsProvider);
    ref
        .read(residenceSettingsProvider.notifier)
        .save(
          current.copyWith(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            establishmentYear: establishmentYear,
            defaultSubscriptionAmount: amount,
            hasImage: _hasImage,
            joinRequestsEnabled: _joinRequestsEnabled,
            buildings: _buildings,
            managementOrganization: _managementOrganizationController.text
                .trim(),
            managementPhone: _managementPhoneController.text.trim(),
            managementOfficeHours: _managementOfficeHoursController.text.trim(),
            bankName: _bankNameController.text.trim(),
            bankAccount: _bankAccountController.text.trim(),
          ),
        );
    _showMessage(localizations.residenceSettingsSaved);
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

class _ResidenceInformationSection extends StatelessWidget {
  const _ResidenceInformationSection({
    required this.nameController,
    required this.addressController,
    required this.yearController,
    required this.hasImage,
    required this.onToggleImage,
  });

  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController yearController;
  final bool hasImage;
  final VoidCallback onToggleImage;

  @override
  Widget build(BuildContext context) {
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
                child: hasImage
                    ? Text(
                        'ي',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppColors.surface),
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
                      localizations.residenceImageOptional,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    DarJarButton(
                      key: const Key('toggle-residence-image-button'),
                      label: hasImage
                          ? localizations.removeImage
                          : localizations.addImage,
                      icon: hasImage
                          ? Icons.delete_outline_rounded
                          : Icons.add_photo_alternate_outlined,
                      variant: DarJarButtonVariant.tertiary,
                      onPressed: onToggleImage,
                    ),
                  ],
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
}

class _ManagementInformationSection extends StatelessWidget {
  const _ManagementInformationSection({
    required this.organizationController,
    required this.phoneController,
    required this.officeHoursController,
    required this.bankNameController,
    required this.bankAccountController,
  });

  final TextEditingController organizationController;
  final TextEditingController phoneController;
  final TextEditingController officeHoursController;
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
          DarJarTextField(
            key: const Key('management-phone-field'),
            controller: phoneController,
            label: localizations.phone,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.large),
          DarJarTextField(
            key: const Key('management-office-hours-field'),
            controller: officeHoursController,
            label: localizations.officeHours,
            prefixIcon: Icons.schedule_outlined,
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
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
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
      ),
    );
  }
}

class _JoiningSection extends StatelessWidget {
  const _JoiningSection({
    required this.settings,
    required this.joinRequestsEnabled,
    required this.onCopy,
    required this.onShowQr,
    required this.onToggleRequests,
  });

  final ResidenceSettings settings;
  final bool joinRequestsEnabled;
  final VoidCallback onCopy;
  final VoidCallback onShowQr;
  final ValueChanged<bool> onToggleRequests;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return _SettingsSection(
      key: const Key('residence-joining-section'),
      icon: Icons.person_add_alt_1_outlined,
      title: localizations.joiningResidence,
      description: localizations.joiningResidenceDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localizations.permanentInvitationLink,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.small),
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: AppColors.primary),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      settings.invitationUrl,
                      key: const Key('permanent-invitation-link'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              DarJarButton(
                key: const Key('copy-invitation-link-button'),
                label: localizations.copyLink,
                icon: Icons.content_copy_rounded,
                variant: DarJarButtonVariant.secondary,
                onPressed: onCopy,
              ),
              DarJarButton(
                key: const Key('show-invitation-qr-button'),
                label: localizations.showQrCode,
                icon: Icons.qr_code_2_rounded,
                variant: DarJarButtonVariant.secondary,
                onPressed: onShowQr,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          const Divider(),
          SwitchListTile(
            key: const Key('join-requests-toggle'),
            contentPadding: EdgeInsets.zero,
            title: Text(localizations.allowJoinRequests),
            subtitle: Text(
              joinRequestsEnabled
                  ? localizations.joinRequestsEnabledDescription
                  : localizations.joinRequestsDisabledDescription,
            ),
            value: joinRequestsEnabled,
            onChanged: onToggleRequests,
          ),
          if (!joinRequestsEnabled)
            Container(
              key: const Key('join-requests-disabled-notice'),
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Text(
                      localizations.invitationExplorationNotice,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StickySaveBar extends StatelessWidget {
  const _StickySaveBar({required this.onSave});

  final VoidCallback onSave;

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

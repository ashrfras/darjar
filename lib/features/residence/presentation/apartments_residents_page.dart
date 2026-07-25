import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_badge.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _ManagementView { apartments, residents }

class ApartmentsResidentsPage extends ConsumerStatefulWidget {
  const ApartmentsResidentsPage({super.key});

  @override
  ConsumerState<ApartmentsResidentsPage> createState() =>
      _ApartmentsResidentsPageState();
}

class _ApartmentsResidentsPageState
    extends ConsumerState<ApartmentsResidentsPage> {
  _ManagementView _view = _ManagementView.apartments;
  String _query = '';
  String? _selectedBuildingId;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(residenceMembersProvider);
    final copy = _Copy.of(context);
    final compact = MediaQuery.sizeOf(context).width < 600;
    final occupiedApartments = data.members
        .map((member) => member.apartmentId)
        .whereType<String>()
        .toSet()
        .length;

    return SingleChildScrollView(
      key: const Key('apartments-management-page'),
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : AppSpacing.xLarge,
        compact ? AppSpacing.small : AppSpacing.xLarge,
        compact ? 12 : AppSpacing.xLarge,
        compact ? 28 : AppSpacing.xxxLarge,
      ),
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DarJarSubpageHeader(
                title: copy.pageTitle,
                description: compact ? null : copy.pageDescription,
                fallbackLocation: AppRoutes.profile,
              ),
              const SizedBox(height: AppSpacing.large),
              _SummaryStrip(
                apartmentCount: data.apartments.length,
                occupiedCount: occupiedApartments,
                residentCount: data.members.length,
                copy: copy,
              ),
              const SizedBox(height: AppSpacing.large),
              SegmentedButton<_ManagementView>(
                key: const Key('apartments-residents-tabs'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _ManagementView.apartments,
                    label: Text(copy.apartments),
                    icon: const Icon(Icons.apartment_outlined),
                  ),
                  ButtonSegment(
                    value: _ManagementView.residents,
                    label: Text(copy.residents),
                    icon: const Icon(Icons.people_outline_rounded),
                  ),
                ],
                selected: {_view},
                onSelectionChanged: (selection) {
                  setState(() => _view = selection.first);
                },
              ),
              const SizedBox(height: AppSpacing.large),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _view == _ManagementView.apartments
                    ? _ApartmentsView(
                        key: const Key('apartments-view'),
                        data: data,
                        copy: copy,
                        selectedBuildingId: _selectedBuildingId,
                        onBuildingSelected: (id) {
                          setState(() => _selectedBuildingId = id);
                        },
                        onAddApartment: _showAddApartmentSheet,
                        onDeleteApartment: _showDeleteApartmentDialog,
                      )
                    : _ResidentsView(
                        key: const Key('residents-view'),
                        data: data,
                        copy: copy,
                        query: _query,
                        onQueryChanged: (value) {
                          setState(() => _query = value);
                        },
                        onAddResident: _showAddResidentSheet,
                        onGroupInvitation: () =>
                            context.push(AppRoutes.groupInvitation),
                        onAssign: _showApartmentDialog,
                        onChangeRole: _showRoleDialog,
                        onRemove: _showRemoveDialog,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showApartmentDialog(ResidenceMember member) async {
    final data = ref.read(residenceMembersProvider);
    final copy = _Copy.of(context);
    final selection = await showDialog<String?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(copy.assignApartmentTo(member.name)),
        children: [
          ListTile(
            leading: const Icon(Icons.link_off_rounded),
            title: Text(copy.notAssigned),
            trailing: member.apartmentId == null
                ? const Icon(Icons.check_rounded, color: AppColors.primary)
                : null,
            onTap: () => Navigator.pop(context, '__none__'),
          ),
          for (final building in data.buildings) ...[
            if (data.buildings.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Text(
                  copy.buildingName(building),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            for (final floor in building.floors)
              for (final apartment in floor.apartments)
                ListTile(
                  leading: const Icon(Icons.door_front_door_outlined),
                  title: Text(copy.apartmentNumber(apartment.number)),
                  subtitle: Text(copy.floorName(floor)),
                  trailing: member.apartmentId == apartment.id
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                        )
                      : null,
                  onTap: () => Navigator.pop(context, apartment.id),
                ),
          ],
        ],
      ),
    );
    if (!mounted || selection == null) return;
    ref
        .read(residenceMembersProvider.notifier)
        .assignApartment(member.id, selection == '__none__' ? null : selection);
    _showSavedMessage(copy.assignmentUpdated);
  }

  Future<void> _showAddResidentSheet() async {
    final data = ref.read(residenceMembersProvider);
    final copy = _Copy.of(context);
    final result = await showModalBottomSheet<_NewResident>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddResidentSheet(data: data, copy: copy),
    );
    if (!mounted || result == null) return;
    final duplicate = data.members.any(
      (member) =>
          member.phone.replaceAll(' ', '') == result.phone.replaceAll(' ', ''),
    );
    if (duplicate) {
      _showSavedMessage(copy.phoneAlreadyRegistered);
      return;
    }
    ref
        .read(residenceMembersProvider.notifier)
        .addResident(
          firstName: result.firstName,
          lastName: result.lastName,
          phone: result.phone,
          apartmentId: result.apartmentId,
        );
    _showSavedMessage(copy.residentAdded);
  }

  Future<void> _showAddApartmentSheet(ResidenceBuilding building) async {
    final copy = _Copy.of(context);
    final result = await showModalBottomSheet<_NewApartment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddApartmentSheet(building: building, copy: copy),
    );
    if (!mounted || result == null) return;
    final floor = building.floors.firstWhere(
      (floor) => floor.id == result.floorId,
    );
    final duplicate = floor.apartments.any(
      (apartment) =>
          apartment.number.trim().toLowerCase() ==
          result.number.trim().toLowerCase(),
    );
    if (duplicate) {
      _showSavedMessage(copy.apartmentAlreadyExists);
      return;
    }
    ref
        .read(residenceMembersProvider.notifier)
        .addApartment(
          buildingId: building.id,
          floorId: result.floorId,
          number: result.number,
        );
    _showSavedMessage(copy.apartmentAdded);
  }

  Future<void> _showDeleteApartmentDialog(ResidenceApartment apartment) async {
    final copy = _Copy.of(context);
    final data = ref.read(residenceMembersProvider);
    final residents = data.members
        .where((member) => member.apartmentId == apartment.id)
        .length;
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        title: Text(copy.deleteApartmentTitle(apartment.number)),
        content: Text(copy.deleteApartmentConfirmation(residents)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(copy.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(copy.delete),
          ),
        ],
      ),
    );
    if (!mounted || delete != true) return;
    ref.read(residenceMembersProvider.notifier).deleteApartment(apartment.id);
    _showSavedMessage(copy.apartmentDeleted);
  }

  Future<void> _showRoleDialog(ResidenceMember member) async {
    final copy = _Copy.of(context);
    final role = await showDialog<ResidenceMemberRole>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(copy.changeRoleFor(member.name)),
        children: [
          for (final role in ResidenceMemberRole.values)
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(copy.role(role)),
              trailing: member.role == role
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, role),
            ),
        ],
      ),
    );
    if (!mounted || role == null) return;
    ref.read(residenceMembersProvider.notifier).changeRole(member.id, role);
    _showSavedMessage(copy.roleUpdated);
  }

  Future<void> _showRemoveDialog(ResidenceMember member) async {
    final copy = _Copy.of(context);
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.person_remove_outlined, color: AppColors.danger),
        title: Text(copy.removeResident),
        content: Text(copy.removeConfirmation(member.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(copy.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(copy.remove),
          ),
        ],
      ),
    );
    if (!mounted || remove != true) return;
    ref.read(residenceMembersProvider.notifier).removeMember(member.id);
    _showSavedMessage(copy.residentRemoved);
  }

  void _showSavedMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _NewApartment {
  const _NewApartment({required this.floorId, required this.number});

  final String floorId;
  final String number;
}

class _NewResident {
  const _NewResident({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.apartmentId,
  });

  final String firstName;
  final String lastName;
  final String phone;
  final String apartmentId;
}

class _CountryCallingCode {
  const _CountryCallingCode(this.code);

  final String code;
}

const _countryCallingCodes = [
  _CountryCallingCode('+212'),
  _CountryCallingCode('+213'),
  _CountryCallingCode('+216'),
  _CountryCallingCode('+33'),
  _CountryCallingCode('+34'),
  _CountryCallingCode('+1'),
];

class _AddResidentSheet extends StatefulWidget {
  const _AddResidentSheet({required this.data, required this.copy});

  final ResidenceMembersData data;
  final _Copy copy;

  @override
  State<_AddResidentSheet> createState() => _AddResidentSheetState();
}

class _AddResidentSheetState extends State<_AddResidentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _countryCode = '+212';
  String? _apartmentId;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final apartments = widget.data.apartments;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xLarge,
        AppSpacing.medium,
        AppSpacing.xLarge,
        AppSpacing.xLarge + bottomInset,
      ),
      child: Form(
        key: _formKey,
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
            const SizedBox(height: AppSpacing.large),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.copy.addResident,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: widget.copy.cancel,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            TextFormField(
              key: const Key('resident-first-name-field'),
              controller: _firstNameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: widget.copy.firstName),
              validator: _requiredValidator,
            ),
            const SizedBox(height: AppSpacing.medium),
            TextFormField(
              key: const Key('resident-last-name-field'),
              controller: _lastNameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: widget.copy.lastName),
              validator: _requiredValidator,
            ),
            const SizedBox(height: AppSpacing.medium),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 132,
                    child: DropdownButtonFormField<String>(
                      key: const Key('resident-country-code-field'),
                      initialValue: _countryCode,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: widget.copy.countryCode,
                      ),
                      items: [
                        for (final country in _countryCallingCodes)
                          DropdownMenuItem(
                            value: country.code,
                            child: Text(country.code),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _countryCode = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: TextFormField(
                      key: const Key('resident-phone-field'),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\s-]')),
                      ],
                      decoration: InputDecoration(
                        labelText: widget.copy.phoneNumber,
                        hintText: widget.copy.phoneHint,
                      ),
                      validator: (value) {
                        final digits = (value ?? '').replaceAll(
                          RegExp(r'\D'),
                          '',
                        );
                        if (digits.length < 8 || digits.length > 12) {
                          return widget.copy.validPhoneRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            DropdownButtonFormField<String>(
              key: const Key('resident-apartment-field'),
              initialValue: _apartmentId,
              isExpanded: true,
              decoration: InputDecoration(labelText: widget.copy.apartment),
              items: [
                for (final building in widget.data.buildings)
                  for (final floor in building.floors)
                    for (final apartment in floor.apartments)
                      DropdownMenuItem(
                        value: apartment.id,
                        child: Text(
                          '${widget.copy.apartmentNumber(apartment.number)} · '
                          '${widget.copy.floorName(floor)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ],
              onChanged: (value) => setState(() => _apartmentId = value),
              validator: (value) =>
                  value == null ? widget.copy.apartmentRequired : null,
            ),
            const SizedBox(height: AppSpacing.xLarge),
            FilledButton.icon(
              key: const Key('confirm-add-resident-button'),
              onPressed: apartments.isEmpty ? null : _submit,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(widget.copy.addResident),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? widget.copy.fieldRequired : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _NewResident(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _formatInternationalPhone(_countryCode, _phoneController.text),
        apartmentId: _apartmentId!,
      ),
    );
  }
}

String _formatInternationalPhone(String countryCode, String nationalNumber) {
  var digits = nationalNumber.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) digits = digits.substring(1);
  final groups = <String>[];
  if (countryCode == '+212' && digits.length == 9) {
    groups
      ..add(digits.substring(0, 1))
      ..addAll([
        for (var index = 1; index < digits.length; index += 2)
          digits.substring(
            index,
            index + 2 < digits.length ? index + 2 : digits.length,
          ),
      ]);
  } else {
    for (var index = 0; index < digits.length; index += 3) {
      groups.add(
        digits.substring(
          index,
          index + 3 < digits.length ? index + 3 : digits.length,
        ),
      );
    }
  }
  return '$countryCode ${groups.join(' ')}';
}

class _AddApartmentSheet extends StatefulWidget {
  const _AddApartmentSheet({required this.building, required this.copy});

  final ResidenceBuilding building;
  final _Copy copy;

  @override
  State<_AddApartmentSheet> createState() => _AddApartmentSheetState();
}

class _AddApartmentSheetState extends State<_AddApartmentSheet> {
  final _numberController = TextEditingController();
  late String _floorId = widget.building.floors.first.id;
  bool _showNumberError = false;

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xLarge,
        AppSpacing.medium,
        AppSpacing.xLarge,
        AppSpacing.xLarge + bottomInset,
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
          const SizedBox(height: AppSpacing.large),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.copy.addApartment,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: widget.copy.cancel,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xLarge),
          Text(
            widget.copy.chooseFloor,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              for (final floor in widget.building.floors)
                ChoiceChip(
                  key: ValueKey('new-apartment-floor-${floor.id}'),
                  label: Text(widget.copy.floorName(floor)),
                  selected: _floorId == floor.id,
                  onSelected: (_) => setState(() => _floorId = floor.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          TextField(
            key: const Key('new-apartment-number-field'),
            controller: _numberController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: widget.copy.apartmentNumberLabel,
              hintText: widget.copy.apartmentNumberHint,
              errorText: _showNumberError
                  ? widget.copy.apartmentNumberRequired
                  : null,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.xLarge),
          FilledButton.icon(
            key: const Key('confirm-add-apartment-button'),
            onPressed: _submit,
            icon: const Icon(Icons.add_rounded),
            label: Text(widget.copy.add),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final number = _numberController.text.trim();
    if (number.isEmpty) {
      setState(() => _showNumberError = true);
      return;
    }
    Navigator.pop(context, _NewApartment(floorId: _floorId, number: number));
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.apartmentCount,
    required this.occupiedCount,
    required this.residentCount,
    required this.copy,
  });

  final int apartmentCount;
  final int occupiedCount;
  final int residentCount;
  final _Copy copy;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _Metric(value: '$apartmentCount', label: copy.apartments),
          ),
          const SizedBox(height: 42, child: VerticalDivider()),
          Expanded(
            child: _Metric(value: '$occupiedCount', label: copy.occupied),
          ),
          const SizedBox(height: 42, child: VerticalDivider()),
          Expanded(
            child: _Metric(value: '$residentCount', label: copy.residents),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

class _ApartmentsView extends StatelessWidget {
  const _ApartmentsView({
    required this.data,
    required this.copy,
    required this.selectedBuildingId,
    required this.onBuildingSelected,
    required this.onAddApartment,
    required this.onDeleteApartment,
    super.key,
  });

  final ResidenceMembersData data;
  final _Copy copy;
  final String? selectedBuildingId;
  final ValueChanged<String> onBuildingSelected;
  final ValueChanged<ResidenceBuilding> onAddApartment;
  final ValueChanged<ResidenceApartment> onDeleteApartment;

  @override
  Widget build(BuildContext context) {
    final hasMultipleBuildings = data.buildings.length > 1;
    final selectedBuilding = data.buildings.firstWhere(
      (building) => building.id == selectedBuildingId,
      orElse: () => data.buildings.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                copy.apartmentsSectionDescription,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            FilledButton.icon(
              key: const Key('add-apartment-button'),
              onPressed: () => onAddApartment(selectedBuilding),
              icon: const Icon(Icons.add_rounded),
              label: Text(copy.addApartment),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        if (hasMultipleBuildings) ...[
          Text(copy.buildings, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.small),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final building in data.buildings) ...[
                  ChoiceChip(
                    key: ValueKey('building-${building.id}'),
                    label: Text(copy.buildingName(building)),
                    selected: building.id == selectedBuilding.id,
                    onSelected: (_) => onBuildingSelected(building.id),
                  ),
                  const SizedBox(width: AppSpacing.small),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.large),
        ],
        for (final floor in selectedBuilding.floors) ...[
          _FloorCard(
            floor: floor,
            members: data.members,
            copy: copy,
            onDeleteApartment: onDeleteApartment,
          ),
          const SizedBox(height: AppSpacing.medium),
        ],
        DarJarCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.inkMuted),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Text(
                  copy.structureSettingsNotice,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.manageResidence),
                child: Text(copy.residenceSettings),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FloorCard extends StatelessWidget {
  const _FloorCard({
    required this.floor,
    required this.members,
    required this.copy,
    required this.onDeleteApartment,
  });

  final ResidenceFloor floor;
  final List<ResidenceMember> members;
  final _Copy copy;
  final ValueChanged<ResidenceApartment> onDeleteApartment;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        key: ValueKey('floor-${floor.id}'),
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.xSmall,
        ),
        title: Text(
          copy.floorName(floor),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(copy.apartmentCount(floor.apartments.length)),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720
                    ? 3
                    : constraints.maxWidth >= 430
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * AppSpacing.small) /
                    columns;
                return Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    for (final apartment in floor.apartments)
                      SizedBox(
                        width: width,
                        child: _ApartmentTile(
                          apartment: apartment,
                          members: members
                              .where(
                                (member) => member.apartmentId == apartment.id,
                              )
                              .toList(growable: false),
                          copy: copy,
                          onDelete: () => onDeleteApartment(apartment),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ApartmentTile extends StatelessWidget {
  const _ApartmentTile({
    required this.apartment,
    required this.members,
    required this.copy,
    required this.onDelete,
  });

  final ResidenceApartment apartment;
  final List<ResidenceMember> members;
  final _Copy copy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey('apartment-${apartment.id}'),
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                ),
                child: const Icon(
                  Icons.door_front_door_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Text(
                  copy.apartmentNumber(apartment.number),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              DarJarBadge(
                label: members.isEmpty
                    ? copy.vacant
                    : copy.residentCount(members.length),
                tone: members.isEmpty
                    ? DarJarBadgeTone.neutral
                    : DarJarBadgeTone.success,
              ),
              IconButton(
                key: ValueKey('delete-apartment-${apartment.id}'),
                tooltip: copy.deleteApartment,
                color: AppColors.inkMuted,
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          if (members.isEmpty)
            Text(copy.noResidents, style: Theme.of(context).textTheme.bodySmall)
          else
            for (final member in members)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xSmall),
                child: Row(
                  children: [
                    _InitialAvatar(name: member.name, radius: 13),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

class _ResidentsView extends StatelessWidget {
  const _ResidentsView({
    required this.data,
    required this.copy,
    required this.query,
    required this.onQueryChanged,
    required this.onAddResident,
    required this.onGroupInvitation,
    required this.onAssign,
    required this.onChangeRole,
    required this.onRemove,
    super.key,
  });

  final ResidenceMembersData data;
  final _Copy copy;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onAddResident;
  final VoidCallback onGroupInvitation;
  final ValueChanged<ResidenceMember> onAssign;
  final ValueChanged<ResidenceMember> onChangeRole;
  final ValueChanged<ResidenceMember> onRemove;

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final residents = data.members
        .where((member) {
          return normalized.isEmpty ||
              member.name.toLowerCase().contains(normalized) ||
              member.phone.contains(normalized);
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: DarJarButton(
                key: const Key('add-resident-button'),
                label: copy.addResident,
                icon: Icons.person_add_alt_1_rounded,
                expanded: true,
                onPressed: onAddResident,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: DarJarButton(
                key: const Key('group-invitation-button'),
                label: copy.groupInvitation,
                icon: Icons.group_add_outlined,
                variant: DarJarButtonVariant.secondary,
                expanded: true,
                onPressed: onGroupInvitation,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        TextField(
          key: const Key('residents-search-field'),
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: copy.searchResidents,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          copy.linkedResidents(residents.length),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.small),
        if (residents.isEmpty)
          DarJarCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xLarge),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_search_outlined,
                    size: 36,
                    color: AppColors.inkMuted,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(copy.noSearchResults),
                ],
              ),
            ),
          )
        else
          for (final member in residents) ...[
            _ResidentCard(
              member: member,
              apartmentLabel: _apartmentLabel(data, member.apartmentId),
              copy: copy,
              onAssign: () => onAssign(member),
              onChangeRole: () => onChangeRole(member),
              onRemove: () => onRemove(member),
            ),
            const SizedBox(height: AppSpacing.small),
          ],
      ],
    );
  }

  String? _apartmentLabel(ResidenceMembersData data, String? apartmentId) {
    if (apartmentId == null) return null;
    for (final building in data.buildings) {
      for (final floor in building.floors) {
        for (final apartment in floor.apartments) {
          if (apartment.id == apartmentId) {
            final prefix = data.buildings.length > 1
                ? '${copy.buildingName(building)} · '
                : '';
            return '$prefix${copy.apartmentNumber(apartment.number)}';
          }
        }
      }
    }
    return null;
  }
}

class _ResidentCard extends StatelessWidget {
  const _ResidentCard({
    required this.member,
    required this.apartmentLabel,
    required this.copy,
    required this.onAssign,
    required this.onChangeRole,
    required this.onRemove,
  });

  final ResidenceMember member;
  final String? apartmentLabel;
  final _Copy copy;
  final VoidCallback onAssign;
  final VoidCallback onChangeRole;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DarJarCard(
      key: ValueKey('resident-${member.id}'),
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InitialAvatar(name: member.name, radius: 23),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    DarJarBadge(
                      label: copy.role(member.role),
                      tone: member.role == ResidenceMemberRole.resident
                          ? DarJarBadgeTone.neutral
                          : DarJarBadgeTone.info,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  member.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.small),
                Row(
                  children: [
                    Icon(
                      apartmentLabel == null
                          ? Icons.link_off_rounded
                          : Icons.door_front_door_outlined,
                      size: 17,
                      color: apartmentLabel == null
                          ? AppColors.warning
                          : AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xSmall),
                    Flexible(
                      child: Text(
                        apartmentLabel ?? copy.notAssigned,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: apartmentLabel == null
                                  ? AppColors.warning
                                  : AppColors.inkMuted,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _DarJarActionsButton(
            key: ValueKey('resident-actions-${member.id}'),
            copy: copy,
            onSelected: (action) {
              switch (action) {
                case _ResidentAction.assign:
                  onAssign();
                  break;
                case _ResidentAction.role:
                  onChangeRole();
                  break;
                case _ResidentAction.remove:
                  onRemove();
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}

enum _ResidentAction { assign, role, remove }

class _DarJarActionsButton extends StatelessWidget {
  const _DarJarActionsButton({
    required this.copy,
    required this.onSelected,
    super.key,
  });

  final _Copy copy;
  final ValueChanged<_ResidentAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) => IconButton(
        tooltip: copy.manage,
        onPressed: () async {
          final action = await _showDarJarActionsMenu(buttonContext);
          if (action != null) onSelected(action);
        },
        icon: const Icon(Icons.more_horiz_rounded),
      ),
    );
  }

  Future<_ResidentAction?> _showDarJarActionsMenu(BuildContext buttonContext) {
    final buttonBox = buttonContext.findRenderObject()! as RenderBox;
    final overlayBox =
        Navigator.of(buttonContext).overlay!.context.findRenderObject()!
            as RenderBox;
    final topLeft = buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final menuWidth = 238.0;
    final menuHeight = 164.0;
    final overlaySize = overlayBox.size;
    final left = (topLeft.dx + buttonBox.size.width - menuWidth)
        .clamp(
          AppSpacing.medium,
          overlaySize.width - menuWidth - AppSpacing.medium,
        )
        .toDouble();
    final preferredTop = topLeft.dy + buttonBox.size.height + AppSpacing.xSmall;
    final top = preferredTop + menuHeight < overlaySize.height
        ? preferredTop
        : topLeft.dy - menuHeight - AppSpacing.xSmall;

    return showGeneralDialog<_ResidentAction>(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: copy.closeMenu,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 140),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            alignment: Alignment.topRight,
            scale: Tween<double>(begin: .96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: menuWidth,
              child: _DarJarActionsMenu(copy: copy),
            ),
          ],
        );
      },
    );
  }
}

class _DarJarActionsMenu extends StatelessWidget {
  const _DarJarActionsMenu({required this.copy});

  final _Copy copy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2417151D),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xSmall),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DarJarMenuItem(
                icon: Icons.door_front_door_outlined,
                label: copy.assignApartment,
                onTap: () => Navigator.pop(context, _ResidentAction.assign),
              ),
              _DarJarMenuItem(
                icon: Icons.admin_panel_settings_outlined,
                label: copy.changeRole,
                onTap: () => Navigator.pop(context, _ResidentAction.role),
              ),
              _DarJarMenuItem(
                icon: Icons.person_remove_outlined,
                label: copy.removeFromResidence,
                danger: true,
                onTap: () => Navigator.pop(context, _ResidentAction.remove),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarJarMenuItem extends StatelessWidget {
  const _DarJarMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.ink;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: danger
                        ? AppColors.danger.withValues(alpha: .08)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  child: Icon(icon, size: 19, color: color),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name, required this.radius});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySoft,
      foregroundColor: AppColors.primary,
      child: Text(
        name.trim().characters.first,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: radius * .85),
      ),
    );
  }
}

class _Copy {
  const _Copy(this.arabic);

  factory _Copy.of(BuildContext context) {
    return _Copy(Localizations.localeOf(context).languageCode == 'ar');
  }

  final bool arabic;

  String get pageTitle => arabic ? 'الشقق والسكان' : 'Apartments & residents';
  String get pageDescription => arabic
      ? 'إدارة توزيع السكان وأدوارهم داخل الإقامة.'
      : 'Manage resident assignments and roles within the residence.';
  String get apartments => arabic ? 'الشقق' : 'Apartments';
  String get residents => arabic ? 'السكان' : 'Residents';
  String get occupied => arabic ? 'مأهولة' : 'Occupied';
  String get buildings => arabic ? 'العمارات' : 'Buildings';
  String get vacant => arabic ? 'فارغة' : 'Vacant';
  String get noResidents => arabic ? 'لا يوجد سكان' : 'No residents';
  String get apartmentsSectionDescription => arabic
      ? 'أضف الشقق وأدر توزيع السكان عليها.'
      : 'Add apartments and manage resident assignments.';
  String get addApartment => arabic ? 'إضافة شقة' : 'Add apartment';
  String get addResident => arabic ? 'إضافة ساكن' : 'Add resident';
  String get firstName => arabic ? 'الاسم' : 'First name';
  String get lastName => arabic ? 'النسب' : 'Last name';
  String get phoneNumber => arabic ? 'رقم الهاتف' : 'Phone number';
  String get countryCode => arabic ? 'رمز الدولة' : 'Country code';
  String get phoneHint => arabic ? '6 12 34 56 78' : '6 12 34 56 78';
  String get apartment => arabic ? 'الشقة' : 'Apartment';
  String get fieldRequired =>
      arabic ? 'هذا الحقل مطلوب.' : 'This field is required.';
  String get validPhoneRequired =>
      arabic ? 'أدخل رقم هاتف صحيحاً.' : 'Enter a valid phone number.';
  String get apartmentRequired =>
      arabic ? 'اختر شقة للساكن.' : 'Choose the resident’s apartment.';
  String get residentAdded => arabic ? 'تمت إضافة الساكن.' : 'Resident added.';
  String get phoneAlreadyRegistered => arabic
      ? 'رقم الهاتف مسجل لساكن آخر.'
      : 'This phone number is already registered.';
  String get chooseFloor => arabic ? 'اختر الطابق' : 'Choose a floor';
  String get apartmentNumberLabel =>
      arabic ? 'رقم أو اسم الشقة' : 'Apartment number or name';
  String get apartmentNumberHint => arabic ? 'مثال: 24' : 'Example: 24';
  String get apartmentNumberRequired => arabic
      ? 'أدخل رقم الشقة أو اسمها.'
      : 'Enter an apartment number or name.';
  String get add => arabic ? 'إضافة' : 'Add';
  String get delete => arabic ? 'حذف' : 'Delete';
  String get deleteApartment => arabic ? 'حذف الشقة' : 'Delete apartment';
  String get apartmentAdded => arabic ? 'تمت إضافة الشقة.' : 'Apartment added.';
  String get apartmentDeleted =>
      arabic ? 'تم حذف الشقة.' : 'Apartment deleted.';
  String get apartmentAlreadyExists => arabic
      ? 'توجد شقة بهذا الرقم في الطابق نفسه.'
      : 'An apartment with this number already exists on this floor.';
  String get residenceSettings => arabic ? 'الإعدادات' : 'Settings';
  String get structureSettingsNotice => arabic
      ? 'تُدار المباني والأجنحة والطوابق من إعدادات الإقامة.'
      : 'Manage buildings, wings, and floors from residence settings.';
  String get searchResidents => arabic
      ? 'ابحث بالاسم أو رقم الهاتف...'
      : 'Search by name or phone number...';
  String get clear => arabic ? 'مسح البحث' : 'Clear search';
  String get noSearchResults => arabic
      ? 'لا يوجد سكان مطابقون لبحثك.'
      : 'No residents match your search.';
  String get notAssigned => arabic ? 'غير معيّن لشقة' : 'Not assigned';
  String get manage => arabic ? 'إدارة الساكن' : 'Manage resident';
  String get closeMenu => arabic ? 'إغلاق القائمة' : 'Close menu';
  String get assignApartment => arabic ? 'تعيين الشقة' : 'Assign apartment';
  String get changeRole => arabic ? 'تغيير الدور' : 'Change role';
  String get removeFromResidence =>
      arabic ? 'إزالة من الإقامة' : 'Remove from residence';
  String get removeResident => arabic ? 'إزالة الساكن؟' : 'Remove resident?';
  String get cancel => arabic ? 'إلغاء' : 'Cancel';
  String get remove => arabic ? 'إزالة' : 'Remove';
  String get assignmentUpdated =>
      arabic ? 'تم تحديث تعيين الشقة.' : 'Apartment assignment updated.';
  String get roleUpdated =>
      arabic ? 'تم تحديث دور الساكن.' : 'Resident role updated.';
  String get residentRemoved =>
      arabic ? 'تمت إزالة الساكن من الإقامة.' : 'Resident removed.';
  String get groupInvitation => arabic ? 'الدعوة الجماعية' : 'Group invitation';

  String buildingName(ResidenceBuilding building) =>
      arabic ? building.nameAr : building.nameEn;
  String floorName(ResidenceFloor floor) =>
      arabic ? floor.nameAr : floor.nameEn;
  String apartmentNumber(String number) =>
      arabic ? 'الشقة $number' : 'Apartment $number';
  String apartmentCount(int count) =>
      arabic ? '$count شقق' : '$count apartments';
  String residentCount(int count) =>
      arabic ? '$count سكان' : '$count residents';
  String linkedResidents(int count) => arabic
      ? '$count من السكان مرتبطون بهذه الإقامة'
      : '$count residents linked to this residence';
  String assignApartmentTo(String name) =>
      arabic ? 'تعيين شقة لـ $name' : 'Assign an apartment to $name';
  String changeRoleFor(String name) =>
      arabic ? 'تغيير دور $name' : 'Change $name’s role';
  String deleteApartmentTitle(String number) =>
      arabic ? 'حذف الشقة $number؟' : 'Delete apartment $number?';
  String deleteApartmentConfirmation(int residentCount) {
    if (residentCount == 0) {
      return arabic
          ? 'سيتم حذف الشقة نهائيًا من هذا الطابق.'
          : 'This apartment will be permanently removed from the floor.';
    }
    return arabic
        ? 'ترتبط بهذه الشقة حسابات سكان عددها $residentCount. سيبقون في الإقامة دون شقة معيّنة.'
        : '$residentCount residents are assigned here. They will remain in the residence without an apartment assignment.';
  }

  String removeConfirmation(String name) => arabic
      ? 'سيُزال $name من الإقامة وتُلغى علاقته بالشقة. لن يتأثر حسابه الشخصي.'
      : '$name will be removed from the residence and unassigned from their apartment. Their personal account will not be affected.';

  String role(ResidenceMemberRole role) => switch (role) {
    ResidenceMemberRole.president => arabic ? 'رئيس' : 'President',
    ResidenceMemberRole.deputy => arabic ? 'نائب' : 'Deputy',
    ResidenceMemberRole.treasurer => arabic ? 'أمين' : 'Treasurer',
    ResidenceMemberRole.resident => arabic ? 'ساكن' : 'Resident',
  };
}

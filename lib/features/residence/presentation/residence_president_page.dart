import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_image_avatar.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/residence/data/residence_context_repository.dart';
import 'package:darjar/features/residence/data/residence_members_repository.dart';
import 'package:darjar/features/residence/presentation/residence_president_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ResidencePresidentPage extends ConsumerStatefulWidget {
  const ResidencePresidentPage({super.key});

  @override
  ConsumerState<ResidencePresidentPage> createState() =>
      _ResidencePresidentPageState();
}

class _ResidencePresidentPageState
    extends ConsumerState<ResidencePresidentPage> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final residence = ref
        .watch(residenceContextProvider)
        .value
        ?.activeResidence;
    final members = ref.watch(residenceMembersProvider);
    final userId = ref.watch(authRepositoryProvider).currentUser?.uid;

    return PopScope(
      canPop: !_saving,
      child: SingleChildScrollView(
        key: const Key('residence-president-page'),
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Align(
          alignment: AlignmentDirectional.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DarJarSubpageHeader(
                  title: strings.residencePresidentTitle,
                  fallbackLocation: AppRoutes.manageResidence,
                  onBack: _saving
                      ? () {}
                      : () => context.canPop()
                            ? context.pop()
                            : context.go(AppRoutes.manageResidence),
                ),
                const SizedBox(height: AppSpacing.large),
                if (_saving || members.isLoading)
                  const LinearProgressIndicator()
                else if (members.hasError)
                  _loadError()
                else if (residence != null && userId != null)
                  _presidentCard(residence, members.requireValue, userId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadError() {
    final strings = AppLocalizations.of(context);
    return DarJarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.residencePresidentLoadFailed),
          const SizedBox(height: AppSpacing.small),
          TextButton.icon(
            onPressed: () => ref.invalidate(residenceMembersProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(strings.accountResolutionRetry),
          ),
        ],
      ),
    );
  }

  Widget _presidentCard(
    UserResidence residence,
    ResidenceMembersData data,
    String userId,
  ) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (:president, :canAppoint, :canTransfer) = residencePresidency(
      residence,
      data,
      userId,
    );
    if (president == null && residence.presidentId != null) {
      return _loadError();
    }
    final apartments = {
      for (final apartment in data.apartments) apartment.id: apartment.number,
    };
    void choosePresident() {
      _choosePresident(residence.id, data, apartments, president, userId);
    }

    return DarJarCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (president == null) ...[
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: const Icon(Icons.badge_outlined),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              strings.residencePresidentVacant,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(strings.residencePresidentVacantDescription),
          ] else ...[
            ResidencePresidentProfile(
              president: president,
              apartmentNumber: apartments[president.apartmentId],
              onChangePresident: canTransfer ? choosePresident : null,
            ),
            const SizedBox(height: AppSpacing.large),
            Text(strings.residencePresidentDuties),
          ],
          if (canAppoint) ...[
            const SizedBox(height: AppSpacing.large),
            FilledButton(
              onPressed: choosePresident,
              child: Text(strings.residencePresidentAppoint),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _choosePresident(
    String residenceId,
    ResidenceMembersData data,
    Map<String, String> apartments,
    ResidenceMember? president,
    String userId,
  ) async {
    if (_saving) return;
    final target = await showModalBottomSheet<ResidenceMember>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (context) => _PresidentPicker(
        members: data.members,
        apartments: apartments,
        currentPresidentId: president?.id,
        userId: userId,
        onInvite: () {
          if (mounted) this.context.push(AppRoutes.groupInvitation);
        },
      ),
    );
    if (target == null || !mounted || _saving) return;
    final strings = AppLocalizations.of(context);
    final isSelf = target.id == userId;
    final (title, description, action) = switch (president) {
      final ResidenceMember previous => (
        strings.residencePresidentChange,
        strings.residencePresidentChangeConfirmation(
          previous.name,
          target.name,
        ),
        strings.residencePresidentConfirmChange,
      ),
      null when isSelf => (
        strings.residencePresidentAssumeTitle,
        strings.residencePresidentAssumeDescription,
        strings.residencePresidentAssume,
      ),
      null => (
        strings.appointResidencePresident,
        strings.residencePresidentAppointConfirmation(target.name),
        strings.residencePresidentConfirmAppointment,
      ),
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (ModalRoute.of(context)?.isCurrent == true) {
                Navigator.pop(context, true);
              }
            },
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(residenceMembersProvider.notifier)
          .transferPresidency(
            residenceId: residenceId,
            actorId: userId,
            currentPresidentId: president?.id,
            newPresidentId: target.id,
          );
      if (!mounted) return;
      _showMessage(
        president == null
            ? strings.residencePresidentAppointed
            : strings.residencePresidentChanged,
      );
      if (!isSelf) context.go(AppRoutes.community);
    } on ResidenceMembersFailure catch (error) {
      if (!mounted) return;
      final needsRefresh =
          error.code == 'permission-denied' ||
          error.code == 'invalid-presidency-transfer';
      _showMessage(
        needsRefresh
            ? strings.residencePresidentSelectionExpired
            : strings.residencePresidentSaveFailed,
      );
      if (needsRefresh) {
        ref.invalidate(residenceContextProvider);
        ref.invalidate(residenceMembersProvider);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PresidentPicker extends StatefulWidget {
  const _PresidentPicker({
    required this.members,
    required this.apartments,
    required this.currentPresidentId,
    required this.userId,
    required this.onInvite,
  });

  final List<ResidenceMember> members;
  final Map<String, String> apartments;
  final String? currentPresidentId;
  final String userId;
  final VoidCallback onInvite;

  @override
  State<_PresidentPicker> createState() => _PresidentPickerState();
}

class _PresidentPickerState extends State<_PresidentPicker> {
  String _query = '';
  ResidenceMember? _selected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final visibleMembers = widget.members
        .where((member) => member.name.toLowerCase().contains(_query))
        .toList();
    final onlySelf =
        widget.currentPresidentId == null &&
        widget.members.length == 1 &&
        widget.members.single.id == widget.userId;
    final selected = _selected;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: FractionallySizedBox(
        heightFactor: .87,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.residencePresidentChoose,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (widget.members.length >= 8) ...[
                const SizedBox(height: AppSpacing.medium),
                DarJarTextField(
                  label: strings.residencePresidentSearch,
                  prefixIcon: Icons.search_rounded,
                  textInputAction: TextInputAction.done,
                  onChanged: (value) => setState(() {
                    _query = value.trim().toLowerCase();
                    if (_selected?.name.toLowerCase().contains(_query) ==
                        false) {
                      _selected = null;
                    }
                  }),
                ),
              ],
              const SizedBox(height: AppSpacing.small),
              Expanded(
                child: visibleMembers.isEmpty
                    ? Center(child: Text(strings.residencePresidentNoResults))
                    : ListView.builder(
                        itemCount: visibleMembers.length,
                        itemBuilder: (context, index) {
                          final member = visibleMembers[index];
                          final isCurrent =
                              member.id == widget.currentPresidentId;
                          final isSelected = member.id == selected?.id;
                          final number = widget.apartments[member.apartmentId];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            enabled: !isCurrent && !onlySelf,
                            selected: isSelected,
                            leading: DarJarUserAvatar(
                              userId: member.id,
                              name: member.name,
                              showImage: member.hasProfileImage,
                            ),
                            title: Text(member.name),
                            subtitle: Wrap(
                              spacing: AppSpacing.small,
                              runSpacing: AppSpacing.xSmall,
                              children: [
                                if (number != null && number.isNotEmpty)
                                  Text(strings.residentApartment(number)),
                                if (member.id == widget.userId)
                                  Text(strings.residencePresidentYou),
                                if (isCurrent)
                                  Text(strings.residencePresidentCurrent),
                              ],
                            ),
                            trailing: onlySelf || isCurrent
                                ? null
                                : Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                  ),
                            onTap: onlySelf || isCurrent
                                ? null
                                : () {
                                    FocusScope.of(context).unfocus();
                                    setState(() => _selected = member);
                                  },
                          );
                        },
                      ),
              ),
              if (keyboardInset == 0) ...[
                const Divider(),
                Wrap(
                  spacing: AppSpacing.small,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(strings.residencePresidentMissingResident),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onInvite();
                      },
                      child: Text(strings.residencePresidentInviteResident),
                    ),
                  ],
                ),
                FilledButton(
                  onPressed: onlySelf || selected != null
                      ? () => Navigator.pop(
                          context,
                          onlySelf ? widget.members.single : selected,
                        )
                      : null,
                  child: Text(
                    onlySelf
                        ? strings.residencePresidentAppointSelf
                        : strings.residencePresidentContinue,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

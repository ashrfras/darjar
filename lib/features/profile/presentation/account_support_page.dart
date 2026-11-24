import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_page_header.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:darjar/features/profile/data/whatsapp_support_repository.dart';
import 'package:darjar/features/profile/presentation/social_contact_icon.dart';
import 'package:darjar/features/profile/presentation/support_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final _officialWhatsAppNumber = const String.fromEnvironment(
  'DARJAR_SUPPORT_WHATSAPP_NUMBER',
  defaultValue: '+212708113590',
).trim().replaceFirst(RegExp(r'^\+'), '');

class AccountSupportPage extends ConsumerWidget {
  const AccountSupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final contactTextAlign = Directionality.of(context) == TextDirection.rtl
        ? TextAlign.right
        : TextAlign.left;
    final auth = ref.watch(authStateProvider);
    final user = auth.value ?? ref.watch(authRepositoryProvider).currentUser;
    final hasWhatsApp = RegExp(
      r'^[1-9][0-9]{6,14}$',
    ).hasMatch(_officialWhatsAppNumber);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xLarge,
        AppSpacing.small,
        AppSpacing.xLarge,
        AppSpacing.xLarge,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DarJarSubpageHeader(
                  title: strings.accountSupportTitle,
                  fallbackLocation: AppRoutes.profile,
                ),
                const SizedBox(height: AppSpacing.medium),
                DarJarCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        strings.accountSupportContactTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(strings.accountSupportContactDescription),
                      const SizedBox(height: AppSpacing.medium),
                      if (hasWhatsApp)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const SocialContactIcon.whatsApp(),
                          title: Text(strings.accountSupportWhatsAppAction),
                          onTap: () => _openContact(
                            context,
                            Uri.https('wa.me', '/$_officialWhatsAppNumber'),
                          ),
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.email_outlined),
                        title: Text(strings.accountSupportEmailAction),
                        subtitle: Text(
                          supportEmail,
                          textDirection: TextDirection.ltr,
                          textAlign: contactTextAlign,
                        ),
                        onTap: () => _openContact(
                          context,
                          Uri(scheme: 'mailto', path: supportEmail),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                if (user != null)
                  _WhatsAppSupportSetting(
                    key: ValueKey(user.uid),
                    userId: user.uid,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openContact(BuildContext context, Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Show the same feedback if the platform cannot open the link.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).supportContactError),
        ),
      );
    }
  }
}

class _WhatsAppSupportSetting extends ConsumerStatefulWidget {
  const _WhatsAppSupportSetting({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<_WhatsAppSupportSetting> createState() =>
      _WhatsAppSupportSettingState();
}

class _WhatsAppSupportSettingState
    extends ConsumerState<_WhatsAppSupportSetting> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final preference = ref.watch(whatsAppSupportEnabledProvider(widget.userId));
    final enabled = preference.asData?.value;
    return DarJarCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text(strings.whatsAppSupportSettingTitle),
            subtitle: Text(strings.whatsAppSupportDescription),
            value: preference.value ?? false,
            onChanged: enabled == null || _saving ? null : _save,
          ),
          if (preference.hasError)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
              ),
              child: TextButton(
                onPressed: () => ref.invalidate(
                  whatsAppSupportEnabledProvider(widget.userId),
                ),
                child: Text(strings.accountResolutionRetry),
              ),
            ),
          if (preference.isLoading || _saving) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Future<void> _save(bool enabled) async {
    setState(() => _saving = true);
    final strings = AppLocalizations.of(context);
    var message = strings.whatsAppSupportSaveError;
    try {
      await ref
          .read(whatsAppSupportRepositoryProvider)
          .setEnabled(widget.userId, enabled);
      message = enabled
          ? strings.whatsAppSupportEnabledMessage
          : strings.whatsAppSupportDisabledMessage;
    } catch (_) {
      // Keep displaying the saved preference when Firestore rejects the update.
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}

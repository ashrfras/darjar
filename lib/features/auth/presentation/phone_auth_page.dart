import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/theme/app_typography.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PhoneAuthPage extends ConsumerStatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  ConsumerState<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends ConsumerState<PhoneAuthPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isSubmitting = false;
  String? _errorCode;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      key: const Key('phone-auth-page'),
      appBar: AppBar(
        title: Text(
          localizations.appName,
          style: AppTypography.brandArabic.copyWith(
            color: AppColors.ink,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          key: const Key('auth-back-button'),
          tooltip: localizations.back,
          onPressed: () => context.go(AppRoutes.onboarding),
          icon: const BackButtonIcon(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xLarge),
          child: Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.large),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_android_rounded,
                      color: AppColors.primary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  Text(
                    _codeSent
                        ? localizations.authCodeTitle
                        : localizations.authPhoneTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    _codeSent
                        ? localizations.authCodeDescription(
                            normalizeMoroccanPhoneNumber(_phoneController.text),
                          )
                        : localizations.authPhoneDescription,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: AppSpacing.xLarge),
                  DarJarCard(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_codeSent) ...[
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 108,
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      labelText: localizations.countryCode,
                                    ),
                                    child: const Text('+212'),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.medium),
                                Expanded(
                                  child: DarJarTextField(
                                    key: const Key('auth-phone-field'),
                                    controller: _phoneController,
                                    label: localizations.phoneNumber,
                                    hint: localizations.authPhoneHint,
                                    keyboardType: TextInputType.number,
                                    textDirection: TextDirection.ltr,
                                    textInputAction: TextInputAction.done,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xLarge),
                          DarJarButton(
                            key: const Key('send-verification-code-button'),
                            label: _isSubmitting
                                ? localizations.authSendingCode
                                : localizations.authSendCode,
                            icon: Icons.sms_outlined,
                            expanded: true,
                            onPressed: _isSubmitting ? null : _sendCode,
                          ),
                        ] else ...[
                          DarJarTextField(
                            key: const Key('auth-verification-code-field'),
                            controller: _codeController,
                            label: localizations.verificationCode,
                            hint: localizations.authCodeHint,
                            prefixIcon: Icons.password_rounded,
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xLarge),
                          DarJarButton(
                            key: const Key('confirm-verification-code-button'),
                            label: _isSubmitting
                                ? localizations.authVerifying
                                : localizations.verify,
                            expanded: true,
                            onPressed: _isSubmitting ? null : _confirmCode,
                          ),
                          const SizedBox(height: AppSpacing.small),
                          DarJarButton(
                            key: const Key('change-phone-number-button'),
                            label: localizations.authChangePhone,
                            variant: DarJarButtonVariant.tertiary,
                            expanded: true,
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() {
                                    _codeSent = false;
                                    _codeController.clear();
                                    _errorCode = null;
                                  }),
                          ),
                        ],
                        if (_errorCode != null) ...[
                          const SizedBox(height: AppSpacing.large),
                          _AuthError(message: _errorMessage(localizations)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  Text(
                    localizations.authPrivacyNotice,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    final phoneNumber = normalizeMoroccanPhoneNumber(_phoneController.text);
    if (!isValidMoroccanMobileNumber(phoneNumber)) {
      setState(() => _errorCode = 'invalid-phone-number');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorCode = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendVerificationCode(phoneNumber);
      if (mounted && ref.read(authRepositoryProvider).currentUser == null) {
        setState(() => _codeSent = true);
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() => _errorCode = error.code);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorCode = 'unknown');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _confirmCode() async {
    if (_codeController.text.length != 6) {
      setState(() => _errorCode = 'invalid-verification-code');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorCode = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmVerificationCode(_codeController.text);
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() => _errorCode = error.code);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorCode = 'unknown');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _errorMessage(AppLocalizations localizations) {
    return switch (_errorCode) {
      'invalid-phone-number' => localizations.authInvalidPhone,
      'invalid-verification-code' ||
      'invalid-verification-id' ||
      'missing-verification-session' => localizations.authInvalidCode,
      'session-expired' => localizations.authCodeExpired,
      'too-many-requests' ||
      'quota-exceeded' => localizations.authTooManyRequests,
      'network-request-failed' => localizations.authNetworkError,
      'unauthorized-domain' => localizations.authUnauthorizedDomain,
      'captcha-check-failed' ||
      'invalid-app-credential' ||
      'missing-app-credential' => localizations.authCaptchaFailed,
      'operation-not-allowed' => localizations.authPhoneOperationNotAllowed,
      _ => localizations.authUnexpectedError,
    };
  }
}

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('auth-error-message'),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

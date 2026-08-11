import 'dart:async';

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/utils/phone_number.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/core/widgets/darjar_card.dart';
import 'package:darjar/core/widgets/darjar_country_code_picker.dart';
import 'package:darjar/core/widgets/darjar_public_page_chrome.dart';
import 'package:darjar/core/widgets/darjar_text_field.dart';
import 'package:darjar/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PhoneAuthPage extends ConsumerStatefulWidget {
  const PhoneAuthPage({super.key});

  @override
  ConsumerState<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends ConsumerState<PhoneAuthPage> {
  static const _resendDelay = Duration(seconds: 60);

  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  Timer? _resendTimer;
  String _countryCode = '+212';
  bool _codeSent = false;
  bool _isSubmitting = false;
  int _resendSecondsRemaining = 0;
  String? _errorCode;
  String? _technicalError;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final usesLocalAuthSimulation = ref.watch(localhostAuthSimulationProvider);

    return Scaffold(
      key: const Key('phone-auth-page'),
      appBar: const DarJarPublicAppBar(
        brandKey: Key('phone-auth-brand'),
        backButtonKey: Key('auth-back-button'),
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
                            _ltrIsolate(
                              formatPhoneNumberForDisplay(_phoneNumber),
                            ),
                          )
                        : localizations.authPhoneDescription,
                    key: const Key('auth-step-description'),
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
                                  child: DarJarCountryCodePickerField(
                                    key: const Key('auth-country-code-field'),
                                    value: _countryCode,
                                    label: localizations.countryCode,
                                    onChanged: (value) =>
                                        setState(() => _countryCode = value),
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
                            inputFormatters: usesLocalAuthSimulation
                                ? [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(32),
                                  ]
                                : [
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
                            key: const Key('resend-verification-code-button'),
                            label: _resendSecondsRemaining > 0
                                ? localizations.authResendCodeIn(
                                    _resendSecondsRemaining,
                                  )
                                : localizations.authResendCode,
                            icon: Icons.refresh_rounded,
                            variant: DarJarButtonVariant.tertiary,
                            expanded: true,
                            onPressed:
                                _isSubmitting || _resendSecondsRemaining > 0
                                ? null
                                : _sendCode,
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
                                    _resendTimer?.cancel();
                                    _codeSent = false;
                                    _resendSecondsRemaining = 0;
                                    _codeController.clear();
                                    _errorCode = null;
                                    _technicalError = null;
                                  }),
                          ),
                        ],
                        if (_errorCode != null) ...[
                          const SizedBox(height: AppSpacing.large),
                          _AuthError(
                            message: _errorMessage(localizations),
                            details: _technicalError,
                          ),
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
    final phoneNumber = _phoneNumber;
    final nationalDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final usesLocalAuthSimulation = ref.read(localhostAuthSimulationProvider);
    final validPhone = usesLocalAuthSimulation
        ? nationalDigits.isNotEmpty
        : _countryCode == '+212'
        ? isValidMoroccanMobileNumber(phoneNumber)
        : nationalDigits.length >= 8 && nationalDigits.length <= 12;
    if (!validPhone) {
      setState(() {
        _errorCode = 'invalid-phone-number';
        _technicalError = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorCode = null;
      _technicalError = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .sendVerificationCode(
            phoneNumber,
            languageCode: Localizations.localeOf(context).languageCode,
          );
      if (mounted && ref.read(authRepositoryProvider).currentUser == null) {
        setState(() {
          _codeSent = true;
          _codeController.clear();
        });
        _startResendCountdown();
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() {
          _errorCode = error.code;
          _technicalError = _formatTechnicalError(error);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorCode = 'unknown';
          _technicalError = _formatTechnicalError(
            AuthFailure('unknown', message: error.toString()),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsRemaining = _resendDelay.inSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendSecondsRemaining--;
        if (_resendSecondsRemaining == 0) timer.cancel();
      });
    });
  }

  String get _phoneNumber => normalizePhoneNumber(
    formatInternationalPhoneNumber(_countryCode, _phoneController.text),
  );

  Future<void> _confirmCode() async {
    final usesLocalAuthSimulation = ref.read(localhostAuthSimulationProvider);
    final validCode = usesLocalAuthSimulation
        ? _codeController.text.isNotEmpty
        : _codeController.text.length == 6;
    if (!validCode) {
      setState(() {
        _errorCode = 'invalid-verification-code';
        _technicalError = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorCode = null;
      _technicalError = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmVerificationCode(_codeController.text);
    } on AuthFailure catch (error) {
      if (mounted) {
        setState(() {
          _errorCode = error.code;
          _technicalError = _formatTechnicalError(error);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorCode = 'unknown';
          _technicalError = _formatTechnicalError(
            AuthFailure('unknown', message: error.toString()),
          );
        });
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
      'local-auth-not-configured' =>
        localizations.authLocalDevelopmentNotConfigured,
      'local-auth-not-authorized' =>
        localizations.authLocalDevelopmentNotConfigured,
      _ => localizations.authUnexpectedError,
    };
  }

  String _formatTechnicalError(AuthFailure error) {
    final rawMessage = error.message?.trim();
    if (rawMessage == null || rawMessage.isEmpty) {
      return 'Verification code: ${error.code}';
    }
    var safeMessage = rawMessage
        .replaceAll(_phoneNumber, '[phone redacted]')
        .replaceAll(RegExp(r'\+?[0-9][0-9 ()-]{7,}[0-9]'), '[phone redacted]')
        .replaceAll(RegExp(r'AIza[A-Za-z0-9_-]{20,}'), '[API key redacted]');
    if (safeMessage.length > 600) {
      safeMessage = '${safeMessage.substring(0, 600)}…';
    }
    return 'Verification code: ${error.code}\n$safeMessage';
  }
}

String _ltrIsolate(String value) => '\u2066$value\u2069';

class _AuthError extends StatelessWidget {
  const _AuthError({required this.message, this.details});

  final String message;
  final String? details;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
                ),
                if (details != null) ...[
                  const SizedBox(height: AppSpacing.small),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: SelectableText(
                      details!,
                      key: const Key('auth-error-technical-details'),
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.danger,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

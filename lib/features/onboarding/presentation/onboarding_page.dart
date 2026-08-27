import 'dart:async';

import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/responsive/responsive_builder.dart';
import 'package:darjar/core/responsive/window_size_class.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:darjar/features/onboarding/presentation/android_app_launcher.dart';
import 'package:darjar/features/onboarding/presentation/web_landing_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    this.showWebLanding,
    this.openAndroidApp = openDarjarAndroidApp,
    super.key,
  });

  /// A test seam for verifying both platform presentations in widget tests.
  /// Production callers leave this null and use the compiled platform.
  final bool? showWebLanding;

  /// A replaceable launcher keeps the Android web handoff testable without
  /// opening an external application from widget tests.
  final Future<void> Function() openAndroidApp;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isWebLanding = showWebLanding ?? kIsWeb;

    if (isWebLanding) {
      void onStart() {
        if (defaultTargetPlatform == TargetPlatform.android) {
          unawaited(openAndroidApp());
          return;
        }
        context.go(AppRoutes.accountResolution);
      }

      return WebLandingPage(
        heroBuilder: (onLearnMore) => _OnboardingHero(
          localizations: localizations,
          allowInternalScroll: false,
          actionLabel: localizations.landingLearnMore,
          actionIcon: Icons.keyboard_arrow_down_rounded,
          onAction: onLearnMore,
        ),
        onStart: onStart,
      );
    }

    return Scaffold(
      key: const Key('onboarding-page'),
      body: SafeArea(child: _OnboardingHero(localizations: localizations)),
    );
  }
}

class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero({
    required this.localizations,
    this.allowInternalScroll = true,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final AppLocalizations localizations;
  final bool allowInternalScroll;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizeClass) {
        final expanded = sizeClass == WindowSizeClass.expanded;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xLarge),
              child: expanded
                  ? Row(
                      children: [
                        Expanded(
                          child: _WelcomeContent(
                            localizations,
                            actionLabel: actionLabel,
                            actionIcon: actionIcon,
                            onAction: onAction,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxxLarge),
                        const Expanded(child: _OnboardingVisual()),
                      ],
                    )
                  : _compactHero(),
            ),
          ),
        );
      },
    );
  }

  Widget _compactHero() {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _OnboardingVisual(compact: true),
        const SizedBox(height: AppSpacing.xxLarge),
        _WelcomeContent(
          localizations,
          actionLabel: actionLabel,
          actionIcon: actionIcon,
          onAction: onAction,
        ),
      ],
    );
    return allowInternalScroll
        ? SingleChildScrollView(child: content)
        : content;
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent(
    this.localizations, {
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final AppLocalizations localizations;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localizations.onboardingHeadline,
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.large),
        Text(
          localizations.onboardingDescription,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xLarge),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            _Pillar(
              icon: Icons.people_rounded,
              label: localizations.community,
              color: AppColors.community,
            ),
            _Pillar(
              icon: Icons.location_on_rounded,
              label: localizations.directory,
              color: AppColors.directory,
            ),
            _Pillar(
              icon: Icons.home_rounded,
              label: localizations.residence,
              color: AppColors.residence,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxLarge),
        DarJarButton(
          key: onAction == null
              ? const Key('start-button')
              : const Key('landing-learn-more-button'),
          label: actionLabel ?? localizations.getStarted,
          icon: actionIcon ?? Icons.arrow_forward_rounded,
          iconAtEnd: true,
          expanded: true,
          onPressed: onAction ?? () => context.go(AppRoutes.accountResolution),
        ),
      ],
    );
  }
}

class _Pillar extends StatelessWidget {
  const _Pillar({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.small),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _OnboardingVisual extends StatelessWidget {
  const _OnboardingVisual({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 220 : 520,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF16988D), Color(0xFF0A5F59)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PositionedDirectional(
            top: compact ? 24 : 72,
            start: compact ? 28 : 68,
            child: const _FloatingIcon(icon: Icons.chat_bubble_outline_rounded),
          ),
          PositionedDirectional(
            bottom: compact ? 24 : 72,
            end: compact ? 28 : 68,
            child: const _FloatingIcon(icon: Icons.handyman_outlined),
          ),
          Container(
            width: compact ? 112 : 180,
            height: compact ? 112 : 180,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.apartment_rounded,
              size: compact ? 58 : 92,
              color: AppColors.directory,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }
}

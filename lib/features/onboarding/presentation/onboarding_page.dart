import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_radius.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/responsive/responsive_builder.dart';
import 'package:darjar/core/responsive/window_size_class.dart';
import 'package:darjar/core/widgets/darjar_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      key: const Key('onboarding-page'),
      body: SafeArea(
        child: ResponsiveBuilder(
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
                            Expanded(child: _WelcomeContent(localizations)),
                            const SizedBox(width: AppSpacing.xxxLarge),
                            const Expanded(child: _OnboardingVisual()),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              const _OnboardingVisual(compact: true),
                              const SizedBox(height: AppSpacing.xxLarge),
                              _WelcomeContent(localizations),
                            ],
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent(this.localizations);

  final AppLocalizations localizations;

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
          key: const Key('start-button'),
          label: localizations.getStarted,
          icon: Icons.arrow_back_rounded,
          expanded: true,
          onPressed: () => context.go(AppRoutes.residenceSetup),
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

import 'package:darjar/app/routing/app_router.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_brand.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PublicLegalPage extends StatelessWidget {
  const PublicLegalPage({
    required this.pageKey,
    required this.title,
    required this.child,
    super.key,
  });

  final Key pageKey;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          key: pageKey,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xLarge,
            AppSpacing.large,
            AppSpacing.xLarge,
            AppSpacing.xxxLarge,
          ),
          child: Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: InkWell(
                      key: const Key('public-darjar-home-link'),
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => context.go(AppRoutes.root),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.small,
                        ),
                        child: DarJarBrand(logoSize: 36),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxLarge),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.large),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/core/widgets/darjar_public_page_chrome.dart';
import 'package:flutter/material.dart';

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
      appBar: const DarJarPublicAppBar(
        brandKey: Key('public-legal-brand'),
        backButtonKey: Key('public-legal-back-button'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: pageKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xLarge,
                  AppSpacing.xxLarge,
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
              const DarJarPublicFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

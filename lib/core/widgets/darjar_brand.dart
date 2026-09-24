import 'package:darjar/app/localization/generated/app_localizations.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/theme/app_typography.dart';
import 'package:flutter/material.dart';

class DarJarBrand extends StatelessWidget {
  const DarJarBrand({this.logoSize = 30, this.fontSize = 20, super.key});

  final double logoSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DarJarLogo(
          asset: 'assets/images/branding/darjar-logo-header-compact.png',
          size: logoSize,
        ),
        const SizedBox(width: AppSpacing.small),
        Text(
          AppLocalizations.of(context).appName,
          style: AppTypography.brandArabic.copyWith(
            color: AppColors.ink,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}

class DarJarLogo extends StatelessWidget {
  const DarJarLogo({
    required this.asset,
    required this.size,
    this.imageKey,
    super.key,
  });

  final String asset;
  final double size;
  final Key? imageKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        theme.brightness == Brightness.dark
            ? theme.colorScheme.onSurface
            : theme.colorScheme.primary,
        BlendMode.srcIn,
      ),
      child: Image.asset(
        asset,
        key: imageKey,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        semanticLabel: 'DarJar',
      ),
    );
  }
}

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
        Image.asset(
          'assets/images/branding/darjar-logo-header-compact.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          semanticLabel: 'DarJar',
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

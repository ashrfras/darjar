import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/core/images/app_image_paths.dart';
import 'package:darjar/core/images/storage_image_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DarJarUserAvatar extends ConsumerWidget {
  const DarJarUserAvatar({
    required this.userId,
    this.radius = 20,
    this.name = '',
    this.showImage = true,
    this.backgroundColor = AppColors.primarySoft,
    this.foregroundColor = AppColors.primary,
    super.key,
  });

  final String userId;
  final double radius;
  final String name;
  final bool showImage;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      child: name.trim().isEmpty
          ? Icon(Icons.person_rounded, size: radius)
          : Text(
              name.trim().characters.first,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: radius * .85,
              ),
            ),
    );
    if (!showImage || userId.isEmpty) return fallback;
    return ref
        .watch(storageImageBytesProvider(userProfileImageStoragePath(userId)))
        .when(
          data: (bytes) => ClipOval(
            child: Image.memory(
              bytes,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              cacheWidth: (radius * 4).round(),
              errorBuilder: (_, _, _) => fallback,
            ),
          ),
          loading: () => fallback,
          error: (_, _) => fallback,
        );
  }
}

class DarJarResidenceAvatar extends ConsumerWidget {
  const DarJarResidenceAvatar({
    required this.residenceId,
    required this.hasImage,
    this.size = 44,
    this.borderRadius = 12,
    super.key,
  });

  final String residenceId;
  final bool hasImage;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.apartment_rounded,
        color: AppColors.primary,
        size: size * .5,
      ),
    );
    if (!hasImage || residenceId.isEmpty) return fallback;
    return ref
        .watch(
          storageImageBytesProvider(
            residenceProfileImageStoragePath(residenceId),
          ),
        )
        .when(
          data: (bytes) => ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              cacheWidth: (size * 4).round(),
              errorBuilder: (_, _, _) => fallback,
            ),
          ),
          loading: () => fallback,
          error: (_, _) => fallback,
        );
  }
}

import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/features/directory/data/directory_repository.dart';
import 'package:darjar/features/directory/presentation/service_category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Optional images; the local preview supplies assets without a storage backend.
final directoryEntryImageProvider = Provider.family<ImageProvider?, String>(
  (ref, entryId) => null,
);

class DirectoryEntryImage extends ConsumerWidget {
  const DirectoryEntryImage({
    required this.entry,
    this.radius = 20,
    this.cover = false,
    super.key,
  });
  final DirectoryEntry entry;
  final double radius;
  final bool cover;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(directoryEntryImageProvider(entry.id));
    final fallback = Icon(
      serviceCategoryIcon(entry.categoryId),
      size: cover ? 68 : radius,
      color: AppColors.primary,
    );
    if (cover) {
      return image == null
          ? Center(child: fallback)
          : Image(
              image: image,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(child: fallback),
            );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySoft,
      foregroundColor: AppColors.primary,
      backgroundImage: image,
      child: image == null ? fallback : null,
    );
  }
}

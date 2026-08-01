import 'package:darjar/core/images/app_image_processing.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

class AppImageSelection {
  const AppImageSelection(this.bytes);

  final Uint8List bytes;
}

class AppImageSelectionFailure implements Exception {
  const AppImageSelectionFailure(this.code);

  final String code;
}

Future<AppImageSelection?> pickAndCompressAppImage() async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
        mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
      ),
    ],
  );
  if (file == null) return null;

  final source = await file.readAsBytes();
  final extension = file.name.split('.').last.toLowerCase();
  final acceptedType =
      appImageSourceTypes.contains(file.mimeType) ||
      {'jpg', 'jpeg', 'png', 'webp'}.contains(extension);
  if (source.isEmpty ||
      source.lengthInBytes > appImageMaxSourceSizeBytes ||
      !acceptedType) {
    throw const AppImageSelectionFailure('invalid-source');
  }

  try {
    final compressed = await compute(compressDisplayImageBytes, source);
    if (compressed.lengthInBytes > displayImageMaxStoredSizeBytes) {
      throw const AppImageSelectionFailure('compressed-image-too-large');
    }
    return AppImageSelection(compressed);
  } catch (error) {
    if (error is AppImageSelectionFailure) rethrow;
    throw const AppImageSelectionFailure('processing-failed');
  }
}

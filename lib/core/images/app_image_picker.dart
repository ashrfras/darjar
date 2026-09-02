import 'package:darjar/core/images/app_image_processing.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class AppImageSelection {
  const AppImageSelection(this.bytes);

  final Uint8List bytes;
}

class AppImageSelectionFailure implements Exception {
  const AppImageSelectionFailure(this.code);

  final String code;
}

class AppPickedImage {
  const AppPickedImage({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String? mimeType;
  final Uint8List bytes;
}

Future<List<AppPickedImage>> pickAppImages({required int limit}) async {
  final picker = ImagePicker();
  final List<XFile> files;
  if (limit == 1) {
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
      requestFullMetadata: false,
    );
    files = [?file];
  } else {
    files = await picker.pickMultiImage(
      imageQuality: 100,
      requestFullMetadata: false,
      limit: limit,
    );
  }

  return Future.wait(
    files.map(
      (file) async => AppPickedImage(
        name: file.name,
        mimeType: file.mimeType,
        bytes: await file.readAsBytes(),
      ),
    ),
  );
}

Future<AppImageSelection?> pickAndCompressAppImage() async {
  final files = await pickAppImages(limit: 1);
  if (files.isEmpty) return null;
  final file = files.single;

  final source = file.bytes;
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

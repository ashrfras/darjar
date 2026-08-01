import 'dart:typed_data';

import 'package:image/image.dart' as image;

const appImageMaxSourceSizeBytes = 8 * 1024 * 1024;
const appImageMaxStoredSizeBytes = 1024 * 1024;
const appImageMaxDimension = 1600;
const appImageTargetSizeBytes = 750 * 1024;
const displayImageMaxStoredSizeBytes = 300 * 1024;
const displayImageMaxDimension = 640;
const displayImageTargetSizeBytes = 180 * 1024;

const appImageSourceTypes = {'image/jpeg', 'image/png', 'image/webp'};

Uint8List compressAppImageBytes(Uint8List sourceBytes) {
  final decoded = image.decodeImage(sourceBytes);
  if (decoded == null) throw const FormatException('invalid-image-data');

  var processed = image.bakeOrientation(decoded);
  if (processed.width > appImageMaxDimension ||
      processed.height > appImageMaxDimension) {
    processed = processed.width >= processed.height
        ? image.copyResize(
            processed,
            width: appImageMaxDimension,
            interpolation: image.Interpolation.average,
          )
        : image.copyResize(
            processed,
            height: appImageMaxDimension,
            interpolation: image.Interpolation.average,
          );
  }
  processed = _flattenTransparency(processed);
  var encoded = image.encodeJpg(processed, quality: 72);
  if (encoded.lengthInBytes > appImageTargetSizeBytes) {
    processed = processed.width >= processed.height
        ? image.copyResize(
            processed,
            width: processed.width > 1280 ? 1280 : processed.width,
            interpolation: image.Interpolation.average,
          )
        : image.copyResize(
            processed,
            height: processed.height > 1280 ? 1280 : processed.height,
            interpolation: image.Interpolation.average,
          );
    encoded = image.encodeJpg(processed, quality: 62);
  }
  if (encoded.lengthInBytes > appImageTargetSizeBytes) {
    encoded = image.encodeJpg(processed, quality: 50);
  }
  if (encoded.lengthInBytes > appImageTargetSizeBytes) {
    processed = processed.width >= processed.height
        ? image.copyResize(
            processed,
            width: processed.width > 960 ? 960 : processed.width,
            interpolation: image.Interpolation.average,
          )
        : image.copyResize(
            processed,
            height: processed.height > 960 ? 960 : processed.height,
            interpolation: image.Interpolation.average,
          );
    encoded = image.encodeJpg(processed, quality: 45);
  }
  return Uint8List.fromList(encoded);
}

Uint8List compressDisplayImageBytes(Uint8List sourceBytes) {
  final decoded = image.decodeImage(sourceBytes);
  if (decoded == null) throw const FormatException('invalid-image-data');

  var processed = image.bakeOrientation(decoded);
  if (processed.width > displayImageMaxDimension ||
      processed.height > displayImageMaxDimension) {
    processed = processed.width >= processed.height
        ? image.copyResize(
            processed,
            width: displayImageMaxDimension,
            interpolation: image.Interpolation.average,
          )
        : image.copyResize(
            processed,
            height: displayImageMaxDimension,
            interpolation: image.Interpolation.average,
          );
  }
  processed = _flattenTransparency(processed);
  var encoded = image.encodeJpg(processed, quality: 68);
  if (encoded.lengthInBytes > displayImageTargetSizeBytes) {
    encoded = image.encodeJpg(processed, quality: 55);
  }
  if (encoded.lengthInBytes > displayImageMaxStoredSizeBytes) {
    processed = processed.width >= processed.height
        ? image.copyResize(
            processed,
            width: processed.width > 480 ? 480 : processed.width,
            interpolation: image.Interpolation.average,
          )
        : image.copyResize(
            processed,
            height: processed.height > 480 ? 480 : processed.height,
            interpolation: image.Interpolation.average,
          );
    encoded = image.encodeJpg(processed, quality: 48);
  }
  if (encoded.lengthInBytes > displayImageMaxStoredSizeBytes) {
    processed = processed.width >= processed.height
        ? image.copyResize(
            processed,
            width: processed.width > 320 ? 320 : processed.width,
            interpolation: image.Interpolation.average,
          )
        : image.copyResize(
            processed,
            height: processed.height > 320 ? 320 : processed.height,
            interpolation: image.Interpolation.average,
          );
    encoded = image.encodeJpg(processed, quality: 44);
  }
  return Uint8List.fromList(encoded);
}

image.Image _flattenTransparency(image.Image source) {
  if (!source.hasAlpha) return source;
  final background = image.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
    backgroundColor: image.ColorRgb8(255, 255, 255),
  );
  return image.compositeImage(background, source);
}

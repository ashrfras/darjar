import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef ResidenceDocumentPicker = Future<XFile?> Function();

final residenceDocumentPickerProvider = Provider<ResidenceDocumentPicker>(
  (ref) => pickResidenceDocument,
);

Future<XFile?> pickResidenceDocument() {
  const types = XTypeGroup(
    label: 'PDF and images',
    extensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    mimeTypes: ['application/pdf', 'image/jpeg', 'image/png', 'image/webp'],
    uniformTypeIdentifiers: [
      'com.adobe.pdf',
      'public.jpeg',
      'public.png',
      'org.webmproject.webp',
    ],
    webWildCards: ['application/pdf', 'image/*'],
  );
  return openFile(acceptedTypeGroups: const [types]);
}

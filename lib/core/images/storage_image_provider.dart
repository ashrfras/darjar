import 'dart:async';
import 'dart:typed_data';

import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageImageBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, storagePath) async {
      final cacheLink = ref.keepAlive();
      final cacheTimer = Timer(const Duration(minutes: 15), cacheLink.close);
      ref.onDispose(cacheTimer.cancel);
      final bytes = await ref
          .watch(firebaseStorageProvider)
          .ref(storagePath)
          .getData(1024 * 1024);
      if (bytes == null) throw StateError('image-not-found');
      return bytes;
    });

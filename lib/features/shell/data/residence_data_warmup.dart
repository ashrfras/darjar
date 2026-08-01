import 'package:darjar/core/performance/data_load_timer.dart';
import 'package:darjar/features/community/data/community_repository.dart';
import 'package:darjar/features/documents/data/residence_documents_repository.dart';
import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final residenceDataWarmupProvider = FutureProvider.autoDispose
    .family<void, String>((ref, residenceId) async {
      final community = ref.watch(communityPostsProvider.future);
      final dues = ref.watch(residentDuesProvider.future);
      final documents = ref.watch(residenceDocumentsProvider.future);
      final attachments = ref.watch(
        residenceTransactionAttachmentsProvider.future,
      );
      await measureDataLoad('residence warm-up', () async {
        await Future.wait<void>([
          _ignoreFailure(community),
          _ignoreFailure(dues),
          _ignoreFailure(documents),
          _ignoreFailure(attachments),
        ]);
      });
    });

Future<void> _ignoreFailure(Future<Object?> future) async {
  try {
    await future;
  } catch (_) {
    // Each destination keeps its own error and retry state.
  }
}

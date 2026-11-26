import 'package:darjar/features/residence/data/residence_setup_progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ResidenceSetupVisibility {
  visible,
  hiddenUnread,
  hiddenRead;

  bool get isHidden => this != visible;
}

final residenceSetupVisibilityProvider = AsyncNotifierProvider.autoDispose
    .family<
      ResidenceSetupVisibilityController,
      ResidenceSetupVisibility,
      ResidenceSetupScope
    >(ResidenceSetupVisibilityController.new);

class ResidenceSetupVisibilityController
    extends AsyncNotifier<ResidenceSetupVisibility> {
  ResidenceSetupVisibilityController(this._scope);

  final ResidenceSetupScope _scope;
  bool _isSaving = false;

  String get _preferenceKey =>
      'residence_setup_visibility/${_scope.userId}/${_scope.residenceId}';

  @override
  Future<ResidenceSetupVisibility> build() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_preferenceKey);
    if (stored == null) {
      // Keep honoring dismissals saved before the reminder was introduced.
      final wasHidden = preferences.getBool(
        'residence_setup_hidden/${_scope.userId}/${_scope.residenceId}',
      );
      return wasHidden == true
          ? ResidenceSetupVisibility.hiddenUnread
          : ResidenceSetupVisibility.visible;
    }
    return switch (stored) {
      'hiddenUnread' => ResidenceSetupVisibility.hiddenUnread,
      'hiddenRead' => ResidenceSetupVisibility.hiddenRead,
      _ => ResidenceSetupVisibility.visible,
    };
  }

  Future<bool> setVisibility(ResidenceSetupVisibility visibility) async {
    if (_isSaving || state.isLoading) return false;
    if (visibility == ResidenceSetupVisibility.hiddenRead &&
        state.value != ResidenceSetupVisibility.hiddenUnread) {
      return false;
    }
    _isSaving = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setString(_preferenceKey, visibility.name)) {
        throw StateError('Could not save residence setup visibility');
      }
      if (ref.mounted) state = AsyncData(visibility);
      return true;
    } finally {
      _isSaving = false;
    }
  }
}

final residenceSetupReminderProvider =
    Provider.autoDispose<({ResidenceSetupScope scope, bool isUnread})?>((ref) {
      final scope = ref.watch(residenceSetupScopeProvider);
      if (scope == null) return null;
      final visibility = ref.watch(residenceSetupVisibilityProvider(scope));
      if (visibility.value?.isHidden != true) return null;
      final progress = ref.watch(residenceSetupProgressProvider(scope));
      if (progress == null || progress.isComplete) return null;
      return (
        scope: scope,
        isUnread: visibility.value == ResidenceSetupVisibility.hiddenUnread,
      );
    });

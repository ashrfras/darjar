import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

const featureDataCacheDuration = Duration(minutes: 5);

/// Keeps feature data warm briefly after its page is closed, then releases
/// subscriptions if the user does not return.
void cacheProviderFor(Ref ref, {Duration duration = featureDataCacheDuration}) {
  final link = ref.keepAlive();
  Timer? timer;

  ref.onCancel(() {
    timer?.cancel();
    timer = Timer(duration, link.close);
  });
  ref.onResume(() {
    timer?.cancel();
    timer = null;
  });
  ref.onDispose(() => timer?.cancel());
}

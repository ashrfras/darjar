import 'package:flutter/foundation.dart';

class DataLoadTimer {
  DataLoadTimer(this.label) : _stopwatch = Stopwatch()..start();

  final String label;
  final Stopwatch _stopwatch;
  bool _finished = false;

  void finish({Object? error}) {
    if (_finished) return;
    _finished = true;
    _stopwatch.stop();
    final result = error == null ? 'ready' : 'failed';
    debugPrint(
      '[DarJar data] $label: $result in ${_stopwatch.elapsedMilliseconds} ms',
    );
  }
}

Future<T> measureDataLoad<T>(String label, Future<T> Function() load) async {
  final timer = DataLoadTimer(label);
  try {
    final result = await load();
    timer.finish();
    return result;
  } catch (error) {
    timer.finish(error: error);
    rethrow;
  }
}

import 'package:darjar/features/residence/data/residence_dues_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResidentDuesRefresh extends ConsumerStatefulWidget {
  const ResidentDuesRefresh({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ResidentDuesRefresh> createState() =>
      _ResidentDuesRefreshState();
}

class _ResidentDuesRefreshState extends ConsumerState<ResidentDuesRefresh> {
  late final AppLifecycleListener _lifecycleListener;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _refreshIfVisible);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isCurrent = ModalRoute.isCurrentOf(context) ?? true;
    // A route on the root navigator can cover the entire shell navigator.
    final isVisible = TickerMode.valuesOf(context).enabled && isCurrent;
    if (isVisible && !_isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshIfVisible());
    }
    _isVisible = isVisible;
  }

  void _refreshIfVisible() {
    if (mounted && _isVisible) ref.invalidate(residentDuesProvider);
  }

  Future<void> _refresh() async {
    ref.invalidate(residentDuesProvider);
    try {
      await ref.read(residentDuesProvider.future);
    } catch (_) {
      // Consumers can read the failure from the provider.
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _refresh, child: widget.child);
  }
}

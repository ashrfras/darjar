import 'package:darjar/app/app.dart';
import 'package:darjar/app/theme/app_colors.dart';
import 'package:darjar/app/theme/app_spacing.dart';
import 'package:darjar/app/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef DarJarInitializer = Future<void> Function();

const darJarInitializationTimeout = Duration(seconds: 15);

class DarJarBootstrap extends StatefulWidget {
  const DarJarBootstrap({
    required this.initialize,
    this.child = const DarJarApp(),
    super.key,
  });

  final DarJarInitializer initialize;
  final Widget child;

  @override
  State<DarJarBootstrap> createState() => _DarJarBootstrapState();
}

class _DarJarBootstrapState extends State<DarJarBootstrap> {
  bool _ready = false;
  bool _initializing = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (_initializing) return;
    setState(() {
      _initializing = true;
      _error = null;
    });
    final stopwatch = Stopwatch()..start();
    try {
      await Future<void>.sync(
        widget.initialize,
      ).timeout(darJarInitializationTimeout);
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint(
          'DarJar performance: Firebase initialization '
          '${stopwatch.elapsedMilliseconds}ms',
        );
      }
      if (mounted) setState(() => _initializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return widget.child;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xLarge),
                child: Column(
                  key: Key(
                    _error == null
                        ? 'bootstrap-loading'
                        : 'bootstrap-load-error',
                  ),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error == null) ...[
                      Image.asset(
                        'assets/images/branding/darjar-logo.png',
                        key: const Key('bootstrap-logo'),
                        width: 84,
                        height: 84,
                        semanticLabel: 'DarJar',
                      ),
                      const SizedBox(height: AppSpacing.xLarge),
                      const SizedBox(
                        width: 240,
                        child: LinearProgressIndicator(
                          key: Key('bootstrap-progress-bar'),
                          minHeight: 4,
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.cloud_off_outlined,
                        color: AppColors.danger,
                        size: 40,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Text(
                        'تعذّر الاتصال بالخدمة. تحقق من الإنترنت ثم حاول مجددًا.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.large),
                      FilledButton.icon(
                        key: const Key('bootstrap-retry-button'),
                        onPressed: _initializing ? null : _initialize,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:url_launcher/url_launcher.dart';
import 'package:darjar/features/onboarding/presentation/app_store_launcher.dart';

export 'package:darjar/features/onboarding/presentation/app_store_launcher.dart'
    show darjarGooglePlayUrl;

const darjarAndroidPackageName = 'ma.raqmain.darjar';

Uri get darjarAndroidIntentUri => Uri.parse(
  'intent://open#Intent;scheme=darjar;package=$darjarAndroidPackageName;'
  'S.browser_fallback_url=${Uri.encodeComponent(darjarGooglePlayUrl)};end',
);

Future<void> openDarjarAndroidApp() async {
  final launched = await launchUrl(
    darjarAndroidIntentUri,
    webOnlyWindowName: '_self',
  );
  if (!launched) {
    await launchUrl(Uri.parse(darjarGooglePlayUrl), webOnlyWindowName: '_self');
  }
}

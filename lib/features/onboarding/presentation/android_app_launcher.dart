import 'package:url_launcher/url_launcher.dart';

const darjarAndroidPackageName = 'ma.raqmain.darjar';
const darjarGooglePlayUrl =
    'https://play.google.com/store/apps/details?id=$darjarAndroidPackageName';

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

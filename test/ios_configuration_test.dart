import 'dart:convert';
import 'dart:io';

import 'package:darjar/features/onboarding/presentation/android_app_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS push notification entitlements match each signing environment', () {
    final developmentEntitlements = File(
      'ios/Runner/RunnerDevelopment.entitlements',
    ).readAsStringSync();
    final releaseEntitlements = File(
      'ios/Runner/Runner.entitlements',
    ).readAsStringSync();
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(developmentEntitlements, contains('<string>development</string>'));
    expect(releaseEntitlements, contains('<string>production</string>'));
    expect(
      project,
      contains(
        'CODE_SIGN_ENTITLEMENTS = Runner/RunnerDevelopment.entitlements',
      ),
    );
    expect(
      project,
      contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements'),
    );
    expect(infoPlist, contains('<string>remote-notification</string>'));
  });

  test('iOS no longer registers the Firebase phone auth callback scheme', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(infoPlist, isNot(contains('<key>CFBundleURLTypes</key>')));
    expect(infoPlist, isNot(contains('app-1-1080325854470-ios')));
  });

  test('mobile app names follow the device language', () {
    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final androidDefault = File(
      'android/app/src/main/res/values/strings.xml',
    ).readAsStringSync();
    final androidArabic = File(
      'android/app/src/main/res/values-ar/strings.xml',
    ).readAsStringSync();
    final iosDefault = File('ios/Runner/Info.plist').readAsStringSync();
    final iosArabic = File(
      'ios/Runner/ar.lproj/InfoPlist.strings',
    ).readAsStringSync();

    expect(androidManifest, contains('android:label="@string/app_name"'));
    expect(androidDefault, contains('>Darjar<'));
    expect(androidArabic, contains('>دارجار<'));
    expect(iosDefault, contains('<string>Darjar</string>'));
    expect(iosArabic, contains('"CFBundleDisplayName" = "دارجار";'));
  });

  test('iOS declares localized photo library access', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
    final english = File(
      'ios/Runner/en.lproj/InfoPlist.strings',
    ).readAsStringSync();
    final arabic = File(
      'ios/Runner/ar.lproj/InfoPlist.strings',
    ).readAsStringSync();

    expect(infoPlist, contains('<key>NSPhotoLibraryUsageDescription</key>'));
    expect(english, contains('"NSPhotoLibraryUsageDescription"'));
    expect(arabic, contains('"NSPhotoLibraryUsageDescription"'));
  });

  test('web uses the professional Arabic browser title', () {
    final indexHtml = File('web/index.html').readAsStringSync();

    expect(indexHtml, contains('<title>دارجار - إقامتك الرقمية</title>'));
    expect(indexHtml, isNot(contains('دعوة للانضمام إلى تطبيق دارجار')));
  });

  test('web invitation links use their own social preview metadata', () {
    final invitationHtml = File('web/join/index.html').readAsStringSync();
    final hostingConfig =
        jsonDecode(File('firebase.json').readAsStringSync())
            as Map<String, dynamic>;
    final hosting = hostingConfig['hosting'] as Map<String, dynamic>;
    final rewrites = hosting['rewrites'] as List<dynamic>;

    expect(
      invitationHtml,
      contains(
        '<meta property="og:title" '
        'content="دعوة للانضمام إلى تطبيق دارجار">',
      ),
    );
    expect(
      invitationHtml,
      contains(
        '<meta property="og:image" '
        'content="https://darjar.app/invitation-preview.png">',
      ),
    );
    expect(File('web/invitation-preview.png').existsSync(), isTrue);
    expect(
      rewrites.first,
      equals({'source': '/join/**', 'destination': '/join/index.html'}),
    );
  });

  test('Android invitation opens the app or falls back to Google Play', () {
    final invitationHtml = File('web/join/index.html').readAsStringSync();

    expect(
      invitationHtml,
      contains(
        '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
      ),
    );
    expect(invitationHtml, contains('height: 112px;'));
    expect(invitationHtml, isNot(contains('window.location.replace(')));
    expect(invitationHtml, contains('id="darjar-open-app-link"'));
    expect(invitationHtml, contains('<h1>تمت دعوتك إلى دارجار</h1>'));
    expect(invitationHtml, contains('<p>اضغط الزر للانتقال إلى التطبيق.</p>'));
    expect(invitationHtml, contains('intent://'));
    expect(invitationHtml, contains('package=ma.raqmain.darjar'));
    expect(invitationHtml, contains('S.browser_fallback_url='));
    expect(
      invitationHtml,
      contains(
        'https://play.google.com/store/apps/details?id=ma.raqmain.darjar',
      ),
    );
    expect(
      invitationHtml,
      contains("flutterBootstrap.src = 'flutter_bootstrap.js'"),
    );
  });

  test('Android home CTA opens DarJar or falls back to Google Play', () {
    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(androidManifest, contains('android:scheme="darjar"'));
    expect(androidManifest, contains('android:host="open"'));
    expect(darjarAndroidIntentUri.scheme, 'intent');
    expect(
      darjarAndroidIntentUri.toString(),
      contains('package=ma.raqmain.darjar'),
    );
    expect(
      darjarAndroidIntentUri.toString(),
      contains(Uri.encodeComponent(darjarGooglePlayUrl)),
    );
  });

  test('Android App Links include every Google Play signing certificate', () {
    final statements =
        jsonDecode(File('web/.well-known/assetlinks.json').readAsStringSync())
            as List<dynamic>;
    final statement = statements.single as Map<String, dynamic>;
    final target = statement['target'] as Map<String, dynamic>;
    final fingerprints = target['sha256_cert_fingerprints'] as List<dynamic>;

    expect(target['package_name'], 'ma.raqmain.darjar');
    expect(
      fingerprints,
      containsAll(<String>[
        'BD:D9:5A:D0:56:F0:7C:3C:01:80:E4:CB:F5:A8:A5:80:59:2B:BE:34:'
            'E1:2F:AD:C7:18:07:6F:CF:0D:6B:65:15',
        '0D:0F:36:D3:E8:87:01:7D:9F:95:F1:5A:01:5B:87:F8:39:78:22:54:'
            '82:F0:FB:DF:5E:B1:3A:2B:1D:5D:83:27',
        '43:5F:6C:35:0A:A2:C0:2F:74:44:CB:54:C4:E0:56:3B:3E:29:4B:02:'
            'F8:06:C9:E8:31:14:44:E6:26:35:5D:28',
      ]),
    );
  });

  test('web public legal routes load the Flutter application directly', () {
    final hostingConfig =
        jsonDecode(File('firebase.json').readAsStringSync())
            as Map<String, dynamic>;
    final hosting = hostingConfig['hosting'] as Map<String, dynamic>;
    final rewrites = hosting['rewrites'] as List<dynamic>;

    expect(
      rewrites,
      containsAll([
        {'source': '/privacy', 'destination': '/index.html'},
        {'source': '/delete-account', 'destination': '/index.html'},
      ]),
    );
    expect(
      rewrites.first,
      equals({'source': '/join/**', 'destination': '/join/index.html'}),
    );
    expect(
      rewrites.last,
      equals({'source': '**', 'destination': '/index.html'}),
    );
  });
}

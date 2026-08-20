import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
    expect(androidDefault, contains('>DarJar<'));
    expect(androidArabic, contains('>دارجار<'));
    expect(iosDefault, contains('<string>DarJar</string>'));
    expect(iosArabic, contains('"CFBundleDisplayName" = "دارجار";'));
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

  test('Android invitation fallback opens the app listing on Google Play', () {
    final invitationHtml = File('web/join/index.html').readAsStringSync();

    expect(invitationHtml, contains('/Android/i.test(navigator.userAgent)'));
    expect(
      invitationHtml,
      contains(
        'https://play.google.com/store/apps/details?id=ma.raqmain.darjar',
      ),
    );
    expect(invitationHtml, contains('window.location.replace('));
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

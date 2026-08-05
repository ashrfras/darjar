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
}

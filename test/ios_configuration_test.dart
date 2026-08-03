import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS registers the Firebase phone auth callback URL scheme', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(infoPlist, contains('<key>CFBundleURLTypes</key>'));
    expect(
      infoPlist,
      contains('app-1-1080325854470-ios-3204b78a259842741b3a87'),
    );
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
  });
}

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
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppPackageInfo {
  const AppPackageInfo({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;
}

final appPackageInfoProvider = FutureProvider<AppPackageInfo>((ref) async {
  final packageInfo = await PackageInfo.fromPlatform();
  return AppPackageInfo(
    version: packageInfo.version,
    buildNumber: packageInfo.buildNumber,
  );
});

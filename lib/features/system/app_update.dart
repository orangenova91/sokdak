import 'package:flutter/foundation.dart';

/// 서버가 요구하는 최소 빌드와 스토어 주소.
class AppUpdateRequirement {
  const AppUpdateRequirement({
    required this.minBuildNumber,
    required this.iosStoreUrl,
    required this.androidStoreUrl,
  });

  factory AppUpdateRequirement.fromJson(Map<String, dynamic> json) {
    return AppUpdateRequirement(
      minBuildNumber: json['min_build_number'] as int? ?? 0,
      iosStoreUrl: json['ios_store_url'] as String? ?? '',
      androidStoreUrl: json['android_store_url'] as String? ?? '',
    );
  }

  final int minBuildNumber;
  final String iosStoreUrl;
  final String androidStoreUrl;
}

/// 설치된 빌드가 최소 빌드보다 낮으면 업데이트가 필요하다.
bool isUpdateRequired({
  required int installedBuild,
  required int minBuildNumber,
}) {
  return installedBuild < minBuildNumber;
}

/// 이 기기의 스토어 주소. 비어 있으면 버튼을 만들지 않는다.
String storeUrlForPlatform({
  required TargetPlatform platform,
  required String iosStoreUrl,
  required String androidStoreUrl,
}) {
  switch (platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return iosStoreUrl;
    default:
      return androidStoreUrl;
  }
}

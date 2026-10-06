import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokdak/features/system/app_update.dart';

void main() {
  test('설치된 빌드가 최소 빌드보다 낮으면 업데이트가 필요하다', () {
    expect(isUpdateRequired(installedBuild: 1, minBuildNumber: 2), isTrue);
    expect(isUpdateRequired(installedBuild: 2, minBuildNumber: 2), isFalse);
    expect(isUpdateRequired(installedBuild: 3, minBuildNumber: 2), isFalse);
  });

  test('플랫폼에 맞는 스토어 주소를 고른다', () {
    expect(
      storeUrlForPlatform(
        platform: TargetPlatform.iOS,
        iosStoreUrl: 'https://apps.apple.com/app/id1',
        androidStoreUrl: 'https://play.google.com/store/apps/details?id=a',
      ),
      'https://apps.apple.com/app/id1',
    );
    expect(
      storeUrlForPlatform(
        platform: TargetPlatform.android,
        iosStoreUrl: '',
        androidStoreUrl: 'https://play.google.com/store/apps/details?id=a',
      ),
      'https://play.google.com/store/apps/details?id=a',
    );
  });
}

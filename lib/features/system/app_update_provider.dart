import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/env.dart';
import '../../core/supabase/supabase_provider.dart';
import 'app_update.dart';

class AppUpdateStatus {
  const AppUpdateStatus({required this.blocked, required this.storeUrl});

  const AppUpdateStatus.allowed() : blocked = false, storeUrl = '';

  final bool blocked;
  final String storeUrl;
}

final appUpdateStatusProvider = FutureProvider<AppUpdateStatus>((ref) async {
  // 웹은 배포 즉시 최신 빌드가 내려가므로 스토어 업데이트 검사가 필요 없다.
  if (kIsWeb || !Env.isConfigured) return const AppUpdateStatus.allowed();

  final raw = await ref.watch(supabaseProvider).rpc('app_update_requirement');
  final row = _firstRow(raw);
  if (row == null) return const AppUpdateStatus.allowed();

  final requirement = AppUpdateRequirement.fromJson(row);
  final info = await PackageInfo.fromPlatform();
  final installedBuild = int.tryParse(info.buildNumber);
  if (installedBuild == null) return const AppUpdateStatus.allowed();

  final blocked = isUpdateRequired(
    installedBuild: installedBuild,
    minBuildNumber: requirement.minBuildNumber,
  );
  return AppUpdateStatus(
    blocked: blocked,
    storeUrl: storeUrlForPlatform(
      platform: defaultTargetPlatform,
      iosStoreUrl: requirement.iosStoreUrl,
      androidStoreUrl: requirement.androidStoreUrl,
    ),
  );
});

Map<String, dynamic>? _firstRow(dynamic raw) {
  final item = raw is List ? raw.firstOrNull : raw;
  if (item is! Map) return null;
  return Map<String, dynamic>.from(item);
}

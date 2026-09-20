import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_provider.dart';
import '../auth/auth_providers.dart';
import 'profile.dart';
import 'profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseProvider));
});

/// 로그인한 사용자의 프로필. 프로필이 아직 없으면 null (온보딩 대상).
final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).fetchProfile(user.id);
});

final regionsProvider = FutureProvider<List<Region>>((ref) async {
  // 지역 목록은 로그인한 사용자만 읽을 수 있다 (RLS).
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.watch(profileRepositoryProvider).fetchRegions();
});

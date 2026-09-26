import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_provider.dart';
import 'auth_repository.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

/// 로그인/로그아웃이 일어날 때마다 다시 계산되는 현재 사용자.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseProvider).auth.currentUser;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseProvider));
});

/// 아이디·비밀번호를 설정해 영구 계정으로 승격했는지.
/// true여야 안전하게 로그아웃할 수 있고(되돌아올 방법이 있음), 로그인 화면 진입도 의미가 있다.
final hasCredentialsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null && !user.isAnonymous;
});

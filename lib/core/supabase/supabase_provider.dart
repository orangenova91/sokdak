import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Env 설정이 없으면 Supabase.initialize가 호출되지 않으므로,
/// 이 프로바이더는 Env.isConfigured 가 true 일 때만 읽어야 한다.
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

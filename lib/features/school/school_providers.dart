import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/config/env.dart';
import '../../core/supabase/supabase_provider.dart';
import '../auth/auth_providers.dart';
import 'neis_client.dart';
import 'school.dart';
import 'school_repository.dart';

final neisClientProvider = Provider<NeisClient>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return NeisClient(client, apiKey: Env.neisApiKey);
});

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepository(ref.watch(supabaseProvider));
});

/// 로그인한 사용자가 등록한 학교. 등록하지 않았으면 null.
final mySchoolProvider = FutureProvider<SchoolSelection?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(schoolRepositoryProvider).fetchMySchool(user.id);
});

/// 등록한 학교의 오늘 급식. 학교 미등록 시 빈 목록.
final todayMealProvider = FutureProvider<List<MealInfo>>((ref) async {
  final school = await ref.watch(mySchoolProvider.future);
  if (school == null) return const [];
  return ref.watch(neisClientProvider)
      .fetchMeals(
        officeCode: school.officeCode,
        schoolCode: school.schoolCode,
        date: DateTime.now(),
      );
});

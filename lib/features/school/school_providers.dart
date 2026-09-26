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

/// 주간 달력에서 앞뒤로 넘겨볼 수 있는 범위. 오늘 기준 과거/미래로 이만큼 가져와서
/// 한 번의 API 호출로 "다가오는 학사일정" 목록과 주간 달력 스와이프를 함께 지원한다.
const scheduleWindowPastDays = 90;
const scheduleWindowFutureDays = 180;

/// 등록한 학교의 학사일정(오늘 기준 -90일 ~ +180일). 학교 미등록 시 빈 목록.
/// 주간 달력과 "다가오는 학사일정" 목록이 이 프로바이더 하나를 함께 사용한다.
final scheduleEventsProvider = FutureProvider<List<SchoolEvent>>((ref) async {
  final school = await ref.watch(mySchoolProvider.future);
  if (school == null) return const [];
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  return ref.watch(neisClientProvider)
      .fetchSchedule(
        officeCode: school.officeCode,
        schoolCode: school.schoolCode,
        from: todayDate.subtract(const Duration(days: scheduleWindowPastDays)),
        to: todayDate.add(const Duration(days: scheduleWindowFutureDays)),
      );
});

/// 오늘부터 다가오는 학사일정 최대 5개.
final upcomingScheduleProvider = FutureProvider<List<SchoolEvent>>((ref) async {
  final events = await ref.watch(scheduleEventsProvider.future);
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  return events.where((e) => !e.date.isBefore(todayDate)).take(5).toList();
});

import 'package:supabase_flutter/supabase_flutter.dart';

import 'school.dart';

class SchoolRepository {
  SchoolRepository(this._client);

  final SupabaseClient _client;

  Future<SchoolSelection?> fetchMySchool(String userId) async {
    final row = await _client
        .from('school_selections')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : SchoolSelection.fromJson(row);
  }

  // upsert()는 ON CONFLICT DO UPDATE로 컴파일되는데, 이때 Postgres가 RLS 컬럼별
  // 권한 검사와 별개로 더 넓은 UPDATE 권한을 요구해 school_selections_update 정책의
  // 컬럼 단위 grant만으로는 42501(permission denied)이 난다. 그래서 직접 조회 후
  // insert/update를 나눠 호출한다.
  Future<void> setSchool({required String userId, required NeisSchool school}) async {
    final existing = await _client
        .from('school_selections')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();
    final data = {
      'office_code': school.officeCode,
      'school_code': school.schoolCode,
      'school_name': school.name,
    };
    if (existing == null) {
      await _client.from('school_selections').insert({'user_id': userId, ...data});
    } else {
      await _client.from('school_selections').update(data).eq('user_id', userId);
    }
  }

  Future<void> clearSchool(String userId) async {
    await _client.from('school_selections').delete().eq('user_id', userId);
  }
}

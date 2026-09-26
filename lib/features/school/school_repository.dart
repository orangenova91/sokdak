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

  Future<void> setSchool({required String userId, required NeisSchool school}) async {
    await _client.from('school_selections').upsert({
      'user_id': userId,
      'office_code': school.officeCode,
      'school_code': school.schoolCode,
      'school_name': school.name,
    });
  }

  Future<void> clearSchool(String userId) async {
    await _client.from('school_selections').delete().eq('user_id', userId);
  }
}

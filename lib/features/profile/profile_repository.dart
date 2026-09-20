import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Profile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  Future<List<Region>> fetchRegions() async {
    final rows = await _client
        .from('regions')
        .select()
        .order('sort_order', ascending: true);
    return rows.map(Region.fromJson).toList();
  }

  Future<void> createProfile({
    required String userId,
    required String nickname,
    required String regionCode,
    required SchoolLevel schoolLevel,
  }) async {
    await _client.from('profiles').insert({
      'id': userId,
      'nickname': nickname,
      'region_code': regionCode,
      'school_level': schoolLevel.value,
    });
  }
}

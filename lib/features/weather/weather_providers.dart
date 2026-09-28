import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../profile/profile_providers.dart';
import 'open_meteo_client.dart';
import 'region_coords.dart';
import 'weather.dart';

final openMeteoClientProvider = Provider<OpenMeteoClient>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OpenMeteoClient(client);
});

/// 프로필 지역 기준 현재 날씨. 지역·좌표가 없으면 null.
final currentWeatherProvider = FutureProvider<CurrentWeather?>((ref) async {
  final profile = await ref.watch(myProfileProvider.future);
  if (profile == null) return null;

  final coords = regionCoordsByCode[profile.regionCode];
  if (coords == null) return null;

  final regions = await ref.watch(regionsProvider.future);
  final regionName =
      regions.where((r) => r.code == profile.regionCode).firstOrNull?.name ??
      profile.regionCode;

  return ref
      .watch(openMeteoClientProvider)
      .fetchCurrent(
        lat: coords.lat,
        lon: coords.lon,
        regionLabel: regionName,
      );
});

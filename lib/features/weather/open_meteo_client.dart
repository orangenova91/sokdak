import 'dart:convert';

import 'package:http/http.dart' as http;

import 'weather.dart';

class WeatherApiException implements Exception {
  const WeatherApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Open-Meteo로 현재 기온·하늘 상태를 가져온다. API 키 없음.
class OpenMeteoClient {
  OpenMeteoClient(this._httpClient);

  final http.Client _httpClient;

  static const _timeout = Duration(seconds: 10);

  Future<CurrentWeather> fetchCurrent({
    required double lat,
    required double lon,
    required String regionLabel,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'current': 'temperature_2m,weather_code',
      'timezone': 'Asia/Seoul',
    });

    final http.Response response;
    try {
      response = await _httpClient.get(uri).timeout(_timeout);
    } catch (_) {
      throw const WeatherApiException('날씨 정보를 불러오지 못했어요.');
    }
    if (response.statusCode != 200) {
      throw const WeatherApiException('날씨 정보를 불러오지 못했어요.');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw const WeatherApiException('날씨 정보를 불러오지 못했어요.');
    }
    final current = body['current'];
    if (current is! Map<String, dynamic>) {
      throw const WeatherApiException('날씨 정보를 불러오지 못했어요.');
    }

    final temp = current['temperature_2m'];
    final code = current['weather_code'];
    if (temp is! num) {
      throw const WeatherApiException('날씨 정보를 불러오지 못했어요.');
    }

    return CurrentWeather(
      temperatureC: temp.round(),
      skyLabel: skyLabelFromWmo(code is num ? code.toInt() : 0),
      regionLabel: regionLabel,
    );
  }
}

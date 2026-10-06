import 'package:flutter/material.dart';

/// 대시보드 헤더에 보여줄 현재 날씨 요약.
class CurrentWeather {
  const CurrentWeather({
    required this.temperatureC,
    required this.skyLabel,
    required this.regionLabel,
  });

  final int temperatureC;
  final String skyLabel;
  final String regionLabel;
}

class WeatherVisual {
  const WeatherVisual(this.icon, this.color);

  final IconData icon;
  final Color color;
}

/// SchoolWorks `weatherVisual`과 같은 규칙으로 하늘 상태 → 아이콘/색.
WeatherVisual weatherVisual(String skyLabel) {
  final sky = skyLabel.trim();

  if (sky.contains('눈')) {
    return const WeatherVisual(Icons.ac_unit, Color(0xFF0EA5E9));
  }
  if (RegExp(r'비|소나기|이슬비').hasMatch(sky)) {
    return const WeatherVisual(Icons.umbrella, Color(0xFF2563EB));
  }
  if (sky.contains('안개')) {
    return const WeatherVisual(Icons.cloud_outlined, Color(0xFF9CA3AF));
  }
  if (sky.contains('흐림') || sky.contains('구름많음')) {
    return const WeatherVisual(Icons.cloud, Color(0xFF6B7280));
  }
  if (sky.contains('구름') || sky.contains('흐림')) {
    return const WeatherVisual(Icons.wb_cloudy_outlined, Color(0xFFF59E0B));
  }
  return const WeatherVisual(Icons.wb_sunny_outlined, Color(0xFFF59E0B));
}

String skyLabelFromWmo(int code) {
  return switch (code) {
    0 => '맑음',
    1 => '대체로 맑음',
    2 => '구름조금',
    3 => '흐림',
    45 || 48 => '안개',
    51 || 53 || 55 => '이슬비',
    61 || 63 || 65 => '비',
    71 || 73 || 75 => '눈',
    80 || 81 || 82 => '소나기',
    85 || 86 => '눈',
    95 || 96 || 99 => '뇌우',
    _ => '흐림',
  };
}

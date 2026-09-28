import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokdak/features/weather/weather.dart';

void main() {
  group('skyLabelFromWmo', () {
    test('맑음·비·눈 코드를 한글 라벨로 바꾼다', () {
      expect(skyLabelFromWmo(0), '맑음');
      expect(skyLabelFromWmo(61), '비');
      expect(skyLabelFromWmo(71), '눈');
      expect(skyLabelFromWmo(80), '소나기');
    });
  });

  group('weatherVisual', () {
    test('하늘 상태에 맞는 아이콘을 고른다', () {
      expect(weatherVisual('맑음').icon, Icons.wb_sunny_outlined);
      expect(weatherVisual('비').icon, Icons.umbrella);
      expect(weatherVisual('눈').icon, Icons.ac_unit);
      expect(weatherVisual('흐림').icon, Icons.cloud);
    });
  });
}

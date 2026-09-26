import 'package:flutter_test/flutter_test.dart';
import 'package:sokdak/features/school/neis_client.dart';

void main() {
  group('parseMenuItems', () {
    test('<br/>로 구분된 메뉴를 목록으로 나눈다', () {
      expect(
        parseMenuItems('쌀밥/잡곡밥<br/>어묵국<br/>돈육불고기'),
        ['쌀밥/잡곡밥', '어묵국', '돈육불고기'],
      );
    });

    test('끝에 붙은 알레르기 번호 괄호를 제거한다', () {
      expect(
        parseMenuItems('돈육불고기 (5.6.10.13)<br/>배추김치 (9)'),
        ['돈육불고기', '배추김치'],
      );
    });

    test('빈 문자열이면 빈 목록을 반환한다', () {
      expect(parseMenuItems(''), isEmpty);
    });
  });

  group('extractNeisRows', () {
    test('정상 응답에서 row 목록을 꺼낸다', () {
      final body = {
        'mealServiceDietInfo': [
          {
            'head': [
              {'list_total_count': 1},
            ],
          },
          {
            'row': [
              {'MMEAL_SC_NM': '중식', 'DDISH_NM': '쌀밥<br/>미역국'},
            ],
          },
        ],
      };
      final rows = extractNeisRows(body, 'mealServiceDietInfo');
      expect(rows, hasLength(1));
      expect(rows.first['MMEAL_SC_NM'], '중식');
    });

    test('데이터 없음(INFO-200)이면 빈 목록을 반환한다', () {
      final body = {
        'RESULT': {'CODE': 'INFO-200', 'MESSAGE': '해당하는 데이터가 없습니다.'},
      };
      expect(extractNeisRows(body, 'mealServiceDietInfo'), isEmpty);
    });

    test('오류(ERROR-*)면 NeisApiException을 던진다', () {
      final body = {
        'RESULT': {'CODE': 'ERROR-300', 'MESSAGE': '필수 값이 누락되어 있습니다.'},
      };
      expect(
        () => extractNeisRows(body, 'mealServiceDietInfo'),
        throwsA(isA<NeisApiException>()),
      );
    });
  });

  group('parseScheduleRows', () {
    Map<String, dynamic> row(String ymd, String eventName) => {
      'AA_YMD': ymd,
      'EVENT_NM': eventName,
    };

    test('반복되는 토요휴업일·방학 나열은 제외하고 의미 있는 이벤트만 남긴다', () {
      final rows = [
        row('20250906', '토요휴업일'),
        row('20250913', '토요휴업일'),
        row('20250725', '여름방학식'),
        row('20250726', '여름방학'),
        row('20250727', '여름방학'),
        row('20250826', '개학식'),
        row('20250815', '광복절'),
      ];
      final events = parseScheduleRows(rows);
      expect(events.map((e) => e.name), [
        '여름방학식',
        '광복절',
        '개학식',
      ]);
    });

    test('날짜순으로 정렬한다', () {
      final rows = [row('20251003', '개천절'), row('20250505', '어린이날')];
      final events = parseScheduleRows(rows);
      expect(events.map((e) => e.name), ['어린이날', '개천절']);
    });

    test('행사명이 비어 있으면 제외한다', () {
      expect(parseScheduleRows([row('20250101', '')]), isEmpty);
    });
  });
}

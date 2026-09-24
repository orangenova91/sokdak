import 'package:flutter_test/flutter_test.dart';
import 'package:sokdak/core/util/content_guard.dart';
import 'package:sokdak/core/util/fuzzy_date.dart';

void main() {
  group('formatFuzzyDate', () {
    final now = DateTime(2026, 9, 20, 15, 30);

    test('같은 날은 오늘 (시각과 무관)', () {
      expect(formatFuzzyDate(DateTime(2026, 9, 20, 0, 1), now: now), '오늘');
      expect(formatFuzzyDate(DateTime(2026, 9, 20, 15, 29), now: now), '오늘');
    });

    test('전날은 어제 (자정 직후·직전 모두)', () {
      expect(formatFuzzyDate(DateTime(2026, 9, 19, 23, 59), now: now), '어제');
      expect(formatFuzzyDate(DateTime(2026, 9, 19, 0, 0), now: now), '어제');
    });

    test('일주일 미만은 N일 전, 이후는 날짜', () {
      expect(formatFuzzyDate(DateTime(2026, 9, 17), now: now), '3일 전');
      expect(formatFuzzyDate(DateTime(2026, 9, 14), now: now), '6일 전');
      expect(formatFuzzyDate(DateTime(2026, 9, 13), now: now), '9월 13일');
    });

    test('미래 시각(기기 시계 오차)은 오늘로 처리', () {
      expect(formatFuzzyDate(DateTime(2026, 9, 21), now: now), '오늘');
    });
  });

  group('ContentGuard', () {
    test('전화번호를 감지한다', () {
      expect(ContentGuard.check('연락은 010-1234-5678 로'), isNotNull);
      expect(ContentGuard.check('01012345678'), isNotNull);
      expect(ContentGuard.check('010 1234 5678'), isNotNull);
    });

    test('주민등록번호 형태를 감지한다', () {
      expect(ContentGuard.check('900101-1234567'), isNotNull);
    });

    test('일반 문장과 짧은 숫자는 통과시킨다', () {
      expect(ContentGuard.check('오늘 3교시에 2학년 5반 수업이 있었어요'), isNull);
      expect(ContentGuard.check('시험은 2026년 11월 12일이에요'), isNull);
    });

    test('욕설을 감지한다 (붙여 쓰기, 띄어 쓰기, 특수문자 우회 모두)', () {
      expect(ContentGuard.check('저 학부모 진짜 씨발 너무하네요'), isNotNull);
      expect(ContentGuard.check('시 발 진짜'), isNotNull);
      expect(ContentGuard.check('시*발 이게 뭐야'), isNotNull);
      expect(ContentGuard.check('ㅅㅂ 진짜 힘드네요'), isNotNull);
      expect(ContentGuard.check('That teacher is such a bitch'), isNotNull);
    });

    test('평범한 단어는 욕설로 오탐하지 않는다', () {
      expect(ContentGuard.check('수업 준비로 정신이 없었어요'), isNull);
      expect(ContentGuard.check('학생이 오늘 발표를 정말 잘했어요'), isNull);
      expect(ContentGuard.check('병가를 내야 할 것 같아요'), isNull);
    });
  });
}

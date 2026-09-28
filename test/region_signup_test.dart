import 'package:flutter_test/flutter_test.dart';
import 'package:sokdak/features/me/region_signup.dart';

RegionSignupStat _stat({
  required String code,
  required String name,
  required int order,
  int teachers = 1000,
  int? signups,
  bool suppressed = false,
}) {
  return RegionSignupStat(
    regionCode: code,
    regionName: name,
    sortOrder: order,
    teacherCount: teachers,
    statsYear: 2026,
    signupCount: suppressed ? null : signups,
    suppressed: suppressed,
  );
}

void main() {
  test('가려진 지역은 인원 없이 집계 중으로 보여 준다', () {
    final stat = RegionSignupStat.fromJson({
      'region_code': 'sejong',
      'region_name': '세종',
      'sort_order': 8,
      'teacher_count': 6563,
      'stats_year': 2026,
      'signup_count': 4,
      'suppressed': true,
    });

    expect(stat.signupCount, isNull);
    expect(stat.rate, isNull);
    expect(stat.summaryLabel, '세종 · 집계 중');
  });

  test('내 교육청을 위에 두고 공개 지역은 비율 순으로 정렬한다', () {
    final arranged = arrangeRegionSignupStats([
      _stat(code: 'seoul', name: '서울', order: 1, teachers: 1000, signups: 10),
      _stat(code: 'busan', name: '부산', order: 2, teachers: 1000, signups: 50),
      _stat(code: 'ulsan', name: '울산', order: 7, teachers: 1000, signups: 20),
      _stat(code: 'jeju', name: '제주', order: 17, suppressed: true),
      _stat(code: 'sejong', name: '세종', order: 8, suppressed: true),
    ], myRegionCode: 'ulsan');

    expect(arranged.map((stat) => stat.regionCode).toList(), [
      'ulsan',
      'busan',
      'seoul',
      'sejong',
      'jeju',
    ]);
  });

  test('가입 비율은 크기에 따라 자릿수를 맞춘다', () {
    expect(formatSignupRate(0), '0%');
    expect(formatSignupRate(0.126), '13%');
    expect(formatSignupRate(0.042), '4.2%');
    expect(formatSignupRate(48 / 11457), '0.42%');
    expect(formatGrouped(11457), '11,457');
  });
}

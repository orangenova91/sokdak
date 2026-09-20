import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sokdak/features/profile/nickname_generator.dart';
import 'package:sokdak/features/profile/profile.dart';

void main() {
  test('추천 닉네임은 항상 DB 제약(2~12자)을 만족한다', () {
    final random = Random(42);
    for (var i = 0; i < 500; i++) {
      final nickname = NicknameGenerator.generate(random);
      expect(nickname.length, inInclusiveRange(2, 12), reason: nickname);
    }
  });

  test('Profile.fromJson 이 DB 행을 변환한다', () {
    final profile = Profile.fromJson({
      'id': 'abc',
      'nickname': '포근한 분필',
      'region_code': 'ulsan',
      'school_level': 'high',
      'is_verified': false,
    });

    expect(profile.nickname, '포근한 분필');
    expect(profile.regionCode, 'ulsan');
    expect(profile.schoolLevel, SchoolLevel.high);
    expect(profile.isVerified, isFalse);
  });

  test('알 수 없는 학교급 값은 기타로 처리한다', () {
    expect(SchoolLevel.fromValue('unknown'), SchoolLevel.other);
  });
}

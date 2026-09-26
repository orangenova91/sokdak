import 'package:flutter_test/flutter_test.dart';
import 'package:sokdak/core/util/username_credentials.dart';

void main() {
  group('UsernameCredentials.validateUsername', () {
    test('영문·숫자·밑줄 4~20자는 통과한다', () {
      expect(UsernameCredentials.validateUsername('teacher_01'), isNull);
      expect(UsernameCredentials.validateUsername('abcd'), isNull);
      expect(
        UsernameCredentials.validateUsername('a' * 20),
        isNull,
        reason: '20자는 허용',
      );
    });

    test('너무 짧거나 길면 거부한다', () {
      expect(UsernameCredentials.validateUsername('abc'), isNotNull);
      expect(UsernameCredentials.validateUsername('a' * 21), isNotNull);
    });

    test('한글이나 특수문자, 공백은 거부한다', () {
      expect(UsernameCredentials.validateUsername('선생님계정'), isNotNull);
      expect(UsernameCredentials.validateUsername('teacher@01'), isNotNull);
      expect(UsernameCredentials.validateUsername('teacher 01'), isNotNull);
    });
  });

  group('UsernameCredentials.validatePassword', () {
    test('6자 이상이면 통과한다', () {
      expect(UsernameCredentials.validatePassword('abcdef'), isNull);
    });

    test('6자 미만이면 거부한다', () {
      expect(UsernameCredentials.validatePassword('abc12'), isNotNull);
    });
  });

  group('UsernameCredentials.toSyntheticEmail', () {
    test('아이디를 소문자로 바꾸고 .invalid 도메인을 붙인다', () {
      expect(
        UsernameCredentials.toSyntheticEmail('Teacher_01'),
        'teacher_01@users.sokdak.invalid',
      );
    });

    test('앞뒤 공백을 제거한다', () {
      expect(
        UsernameCredentials.toSyntheticEmail('  teacher01  '),
        'teacher01@users.sokdak.invalid',
      );
    });

    test('같은 아이디는 대소문자와 무관하게 같은 주소가 된다 (중복 판별 근거)', () {
      expect(
        UsernameCredentials.toSyntheticEmail('Teacher01'),
        UsernameCredentials.toSyntheticEmail('teacher01'),
      );
    });
  });
}

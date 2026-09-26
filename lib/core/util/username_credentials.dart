/// 아이디·비밀번호 로그인에 쓰는 규칙과 변환 규칙.
///
/// Supabase Auth의 비밀번호 로그인은 "이메일 + 비밀번호" 구조로만 동작하므로,
/// 이용자가 정한 아이디를 실제로 존재하지 않는(.invalid) 내부용 주소로 변환해서 쓴다.
/// .invalid 는 RFC 2606이 "절대 실제 도메인이 될 수 없다"고 예약해 둔 TLD라서,
/// 메일을 보내거나 받을 일이 없는 이 용도에 안전하다. 화면에는 이 변환이 전혀
/// 드러나지 않고, 이용자는 "아이디"만 입력한다.
class UsernameCredentials {
  UsernameCredentials._();

  static const _domain = 'users.sokdak.invalid';

  static final _usernamePattern = RegExp(r'^[a-zA-Z0-9_]{4,20}$');

  /// 아이디로 쓸 수 없으면 안내 문구, 문제 없으면 null.
  static String? validateUsername(String username) {
    if (!_usernamePattern.hasMatch(username)) {
      return '아이디는 영문, 숫자, _(밑줄)로 4~20자여야 해요.';
    }
    return null;
  }

  /// 비밀번호로 쓸 수 없으면 안내 문구, 문제 없으면 null.
  static String? validatePassword(String password) {
    if (password.length < 6) return '비밀번호는 6자 이상이어야 해요.';
    return null;
  }

  /// 아이디를 Supabase에 보낼 내부용 주소로 바꾼다. 실제로 발송되지 않는다.
  static String toSyntheticEmail(String username) =>
      '${username.trim().toLowerCase()}@$_domain';
}

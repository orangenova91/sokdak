import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/util/username_credentials.dart';

/// 이미 다른 계정이 쓰고 있는 아이디로 설정을 시도했을 때 던진다.
class UsernameTakenException implements Exception {
  const UsernameTakenException();
}

/// 아이디 또는 비밀번호가 일치하지 않을 때 던진다.
class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();
}

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// 지금 로그인된 (익명) 계정에 아이디·비밀번호를 설정해 영구 계정으로 승격한다.
  /// 계정 ID가 그대로 유지되므로 이미 쓴 글·댓글·공감은 전부 남는다.
  ///
  /// 아이디(이메일)와 비밀번호를 한 번에 보내면, 비밀번호가 기존과 같을 때 Supabase가
  /// "새 비밀번호가 이전과 같다"며 요청 전체를 거부해 아이디만 고치는 것도 막힌다
  /// (가입 2단계에서 뒤로 가서 아이디만 고치고 비밀번호는 그대로 두는 경우 실제로 발생).
  /// 그래서 두 번에 나눠 보낸다.
  ///
  /// 또한 Supabase는 **이미 확정된 이메일을 다른 값으로 바꾸는 것** 자체를 이메일
  /// 확인 절차 없이는 허용하지 않는다(우리가 쓰는 가짜 도메인은 그 절차를 절대
  /// 통과할 수 없다). 그래서 아이디를 실제로 바꾸는 경우에는, 아직 프로필이 없는
  /// 단계라는 점을 이용해 지금 계정을 지우고 새 익명 계정을 하나 만들어 그 위에
  /// 다시 설정한다. 이용자 입장에서는 그냥 "아이디가 바뀌었다"로만 보인다.
  Future<void> setCredentials({
    required String username,
    required String password,
  }) async {
    final current = _client.auth.currentUser;
    final targetEmail = UsernameCredentials.toSyntheticEmail(username);
    final changingUsername =
        current != null && !current.isAnonymous && current.email != targetEmail;

    if (changingUsername) {
      try {
        await _client.rpc('delete_my_account');
      } on PostgrestException {
        // 계정이 이미 없는 상태 등은 무시하고 새 익명 계정으로 이어간다.
      }
      await _client.auth.signInAnonymously();
    }

    try {
      await _client.auth.updateUser(UserAttributes(email: targetEmail));
    } on AuthException catch (e) {
      if (e.code == 'email_exists' || e.code == 'user_already_exists') {
        throw const UsernameTakenException();
      }
      rethrow;
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (e) {
      // 이미 이 비밀번호로 설정돼 있다는 뜻이라 실질적으로는 성공과 같다.
      if (e.code != 'same_password') rethrow;
    }
  }

  /// 아이디·비밀번호로 로그인한다. 성공하면 그 아이디로 승격했던 기존 계정에 연결된다.
  Future<void> signInWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: UsernameCredentials.toSyntheticEmail(username),
        password: password,
      );
    } on AuthException catch (e) {
      if (e.code == 'invalid_credentials') {
        throw const InvalidCredentialsException();
      }
      rethrow;
    }
  }

  /// 아이디·비밀번호를 설정해 둔 계정만 안전하게 로그아웃할 수 있다.
  /// (설정 전에는 되돌아올 방법이 없어 이 메서드를 호출하는 화면을 아예 숨긴다.)
  Future<void> signOut() => _client.auth.signOut();
}

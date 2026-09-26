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
  Future<void> setCredentials({
    required String username,
    required String password,
  }) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(
          email: UsernameCredentials.toSyntheticEmail(username),
          password: password,
        ),
      );
    } on AuthException catch (e) {
      if (e.code == 'email_exists' || e.code == 'user_already_exists') {
        throw const UsernameTakenException();
      }
      rethrow;
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

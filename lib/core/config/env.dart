/// 빌드 시점에 `--dart-define-from-file=env.json` 으로 주입되는 설정값.
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// 나이스 Open API 인증키. 없으면 급식 대시보드 기능을 숨긴다.
  static const neisApiKey = String.fromEnvironment('NEIS_API_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static bool get isNeisConfigured => neisApiKey.isNotEmpty;
}

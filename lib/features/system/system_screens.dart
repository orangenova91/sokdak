import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_provider.dart';
import '../profile/profile_providers.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// env.json 없이 실행했을 때 보이는 안내 화면.
class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Supabase 설정이 필요해요.\n'
            'flutter run --dart-define-from-file=env.json 으로 실행해 주세요.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// 프로필을 불러오지 못했을 때 (네트워크 오류, 서버에서 삭제된 계정 등).
class ProfileErrorScreen extends ConsumerWidget {
  const ProfileErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('계정 정보를 불러오지 못했어요.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(myProfileProvider),
                child: const Text('다시 시도'),
              ),
              TextButton(
                onPressed: () => ref.read(supabaseProvider).auth.signOut(),
                child: const Text('처음부터 다시 시작'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

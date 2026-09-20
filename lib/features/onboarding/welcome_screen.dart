import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _loading = false;
  bool _agreed = false;
  String? _error;

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 로그인에 성공하면 라우터가 자동으로 프로필 설정 화면으로 보낸다.
      await ref.read(supabaseProvider).auth.signInAnonymously();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = '시작하지 못했어요. 잠시 후 다시 시도해 주세요. (${e.message})');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '네트워크 상태를 확인하고 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('교무실 속닥속닥', style: textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    '선생님들의 익명 이야기 공간',
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _Point(
                    icon: Icons.visibility_off_outlined,
                    title: '이메일도 전화번호도 필요 없어요',
                    body: '닉네임, 지역, 학교급만 정하면 바로 시작할 수 있어요.',
                  ),
                  const _Point(
                    icon: Icons.phone_iphone,
                    title: '앱을 지우면 계정이 사라져요',
                    body: '익명 계정은 복구할 수 없어요. 폰을 바꾸거나 앱을 다시 설치하면 새로 시작해야 해요.',
                  ),
                  const _Point(
                    icon: Icons.shield_outlined,
                    title: '모두가 안전한 공간을 위해',
                    body: '학생·학부모·동료 교사의 실명이나 개인정보는 올리지 말아 주세요.',
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _agreed,
                    onChanged: (value) =>
                        setState(() => _agreed = value ?? false),
                    title: const Text('이용약관과 개인정보 처리방침에 동의합니다 (필수)'),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => context.push('/legal/terms'),
                        child: const Text('이용약관 보기'),
                      ),
                      TextButton(
                        onPressed: () => context.push('/legal/privacy'),
                        child: const Text('개인정보 처리방침 보기'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_error != null) ...[
                    Text(_error!, style: TextStyle(color: colors.error)),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_loading || !_agreed) ? null : _start,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('시작하기'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(body, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

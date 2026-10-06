import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/util/username_credentials.dart';
import '../auth/auth_providers.dart';
import '../auth/auth_repository.dart';

/// 가입 1단계: 익명 계정에 아이디·비밀번호를 설정해 영구 계정으로 승격한다.
/// 성공하면 (익명 상태가 풀리면) 라우터가 자동으로 2단계(프로필 만들기)로 보낸다.
///
/// 2단계에서 "뒤로"를 누르면 이미 설정한 값을 고치러 이 화면으로 다시 돌아올 수
/// 있다. 그 경우 아이디는 지금 계정의 값을 미리 채워 준다(비밀번호는 원문을 다시
/// 알 수 없으니 항상 비워 둔다).
class CredentialsStepScreen extends ConsumerStatefulWidget {
  const CredentialsStepScreen({super.key});

  @override
  ConsumerState<CredentialsStepScreen> createState() =>
      _CredentialsStepScreenState();
}

class _CredentialsStepScreenState extends ConsumerState<CredentialsStepScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _submitting = false;
  bool _cancelling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    // 이미 아이디를 정해 둔 계정이 고치러 돌아온 경우, 가짜 이메일에서 아이디를 되살려 보여준다.
    final existingUsername = (user != null && !user.isAnonymous)
        ? user.email?.split('@').first
        : null;
    _usernameController = TextEditingController(text: existingUsername ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// 아직 계정 보호를 설정하지 않았다면(익명 상태) 취소할 데이터가 없으니
  /// 바로 로그아웃하고 처음으로 돌아간다.
  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('처음으로 돌아가지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .setCredentials(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          );
      // 성공하면 계정이 더 이상 익명이 아니게 되어, 라우터가 자동으로 다음
      // 단계(프로필 만들기)로 보낸다.
      if (mounted) context.go('/profile-details');
    } on UsernameTakenException {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = '이미 사용 중인 아이디예요. 다른 아이디를 써 주세요.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = '설정하지 못했어요. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final busy = _submitting || _cancelling;

    return Scaffold(
      appBar: AppBar(
        title: const Text('계정 보호 설정'),
        leading: IconButton(
          icon: _cancelling
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.arrow_back),
          tooltip: '처음으로',
          onPressed: busy ? null : _cancel,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '아이디와 비밀번호를 정해 주세요. 이메일이나 전화번호는 필요 없어요. 앱을 '
                      '지우거나 기기를 바꾼 뒤에도 이 정보로 같은 계정에 다시 로그인할 수 있어요.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '단, 아이디·비밀번호를 잊으면 이 방법으로도 복구할 수 없으니 잘 기억해 주세요.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.error),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '아이디',
                        helperText: '영문, 숫자, _(밑줄)로 4~20자',
                      ),
                      validator: (value) =>
                          UsernameCredentials.validateUsername(value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '비밀번호',
                        helperText: '6자 이상',
                      ),
                      validator: (value) =>
                          UsernameCredentials.validatePassword(value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '비밀번호 확인',
                      ),
                      validator: (value) => value != _passwordController.text
                          ? '비밀번호가 서로 달라요.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      Text(_error!, style: TextStyle(color: colors.error)),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: busy ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('다음'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

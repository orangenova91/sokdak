import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_providers.dart';
import 'auth_repository.dart';

/// 아이디·비밀번호를 이미 설정해 둔 이용자가 다른 기기에서, 또는 로그아웃 뒤에 돌아오는 화면.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithUsername(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          );
      // 로그인에 성공하면 라우터가 자동으로 홈으로 보낸다.
      if (mounted) context.go('/');
    } on InvalidCredentialsException {
      if (!mounted) return;
      setState(() => _error = '아이디 또는 비밀번호가 올바르지 않아요.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '네트워크 상태를 확인하고 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
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
                      '내 정보 > 계정 보호 설정에서 아이디·비밀번호를 만들어 둔 분만 로그인할 수 있어요. '
                      '만든 적이 없다면 시작 화면에서 새로 시작해 주세요.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '아이디',
                      ),
                      validator: (value) =>
                          (value ?? '').trim().isEmpty ? '아이디를 입력해 주세요.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '비밀번호',
                      ),
                      validator: (value) =>
                          (value ?? '').isEmpty ? '비밀번호를 입력해 주세요.' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      Text(_error!, style: TextStyle(color: colors.error)),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('로그인'),
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

// 실수로 아이디 자리에 아이디 규칙에 맞지 않는 값을 넣었을 때 미리 알려주고 싶다면
// UsernameCredentials.validateUsername 를 validator에 연결해도 되지만,
// 로그인 화면은 "가입 때 이미 통과한 값"을 다시 입력하는 곳이라 굳이 막지 않는다.

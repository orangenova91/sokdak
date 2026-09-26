import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/util/username_credentials.dart';
import 'auth_providers.dart';
import 'auth_repository.dart';

/// 익명 계정에 아이디·비밀번호를 설정해 영구 계정으로 승격하는 화면.
/// 지금까지 쓴 글·댓글은 계정 ID가 그대로라서 전부 유지된다.
class CredentialsSetupScreen extends ConsumerStatefulWidget {
  const CredentialsSetupScreen({super.key});

  @override
  ConsumerState<CredentialsSetupScreen> createState() =>
      _CredentialsSetupScreenState();
}

class _CredentialsSetupScreenState
    extends ConsumerState<CredentialsSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
          .setCredentials(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정했어요. 이제 이 아이디로 다른 기기에서도 로그인할 수 있어요.')),
      );
      context.pop();
    } on UsernameTakenException {
      if (!mounted) return;
      setState(() => _error = '이미 사용 중인 아이디예요. 다른 아이디를 써 주세요.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '설정하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('계정 보호 설정')),
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
                      '아이디와 비밀번호를 정해 두면 앱을 지우거나 기기를 바꾼 뒤에도 로그인으로 '
                      '지금 계정(닉네임, 글, 댓글 포함)에 다시 들어올 수 있어요. 이메일이나 전화번호는 '
                      '여전히 필요 없어요.',
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
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('설정하기'),
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

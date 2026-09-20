import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../profile/nickname_generator.dart';
import '../profile/profile.dart';
import '../profile/profile_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController(
    text: NicknameGenerator.generate(),
  );

  String? _regionCode;
  SchoolLevel? _schoolLevel;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit(String regionCode) async {
    if (!_formKey.currentState!.validate()) return;
    final schoolLevel = _schoolLevel;
    if (schoolLevel == null) {
      setState(() => _error = '학교급을 선택해 주세요.');
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .createProfile(
            userId: user.id,
            nickname: _nicknameController.text.trim(),
            regionCode: regionCode,
            schoolLevel: schoolLevel,
          );
      // 프로필이 생기면 라우터가 자동으로 홈으로 보낸다.
      ref.invalidate(myProfileProvider);
      await ref.read(myProfileProvider.future);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = '프로필을 만들지 못했어요. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final regions = ref.watch(regionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('프로필 만들기')),
      body: SafeArea(
        child: regions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('지역 목록을 불러오지 못했어요.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(regionsProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
          data: (regionList) {
            final firstActive = regionList.where((r) => r.isActive).firstOrNull;
            final selectedCode = _regionCode ?? firstActive?.code;
            final selected = regionList
                .where((r) => r.code == selectedCode)
                .firstOrNull;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('닉네임', style: textTheme.titleSmall),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nicknameController,
                          maxLength: 12,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            helperText: '실명이나 학교 이름은 쓰지 않는 걸 권해요.',
                            suffixIcon: IconButton(
                              tooltip: '다른 닉네임 추천',
                              icon: const Icon(Icons.casino_outlined),
                              onPressed: () => _nicknameController.text =
                                  NicknameGenerator.generate(),
                            ),
                          ),
                          validator: (value) {
                            final length = (value ?? '').trim().length;
                            if (length < 2) return '닉네임은 2자 이상이어야 해요.';
                            if (length > 12) return '닉네임은 12자 이하여야 해요.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Text('지역', style: textTheme.titleSmall),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCode,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final region in regionList)
                              DropdownMenuItem(
                                value: region.code,
                                child: Text(
                                  region.isActive
                                      ? region.name
                                      : '${region.name} (준비 중)',
                                ),
                              ),
                          ],
                          onChanged: (code) =>
                              setState(() => _regionCode = code),
                        ),
                        if (selected != null && !selected.isActive)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${selected.name} 지역은 아직 글쓰기가 열리지 않았어요. '
                              '가입은 할 수 있고, 열리면 바로 이용할 수 있어요.',
                              style: textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(height: 24),
                        Text('학교급', style: textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final level in SchoolLevel.values)
                              ChoiceChip(
                                label: Text(level.label),
                                selected: _schoolLevel == level,
                                onSelected: (_) =>
                                    setState(() => _schoolLevel = level),
                              ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        if (_error != null) ...[
                          Text(_error!, style: TextStyle(color: colors.error)),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: (_submitting || selectedCode == null)
                                ? null
                                : () => _submit(selectedCode),
                            child: _submitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('완료'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

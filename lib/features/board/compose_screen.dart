import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/util/content_guard.dart';
import '../profile/profile_providers.dart';
import 'board_providers.dart';
import 'models.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key, required this.board});

  final Board board;

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String? _category;
  bool _submitting = false;
  String? _error;

  /// 속닥방은 제목 없이 짧게 쓸 수 있고, 노하우방은 제목이 필요하다.
  bool get _titleRequired => widget.board == Board.knowhow;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit(String category) async {
    if (!_formKey.currentState!.validate()) return;
    final profile = ref.read(myProfileProvider).value;
    if (profile == null) return;

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    final guardMessage = ContentGuard.check('$title\n$body');
    if (guardMessage != null) {
      setState(() => _error = guardMessage);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(boardRepositoryProvider)
          .createPost(
            board: widget.board,
            category: category,
            regionCode: profile.regionCode,
            title: title.isEmpty ? null : title,
            body: body,
          );
      ref.invalidate(feedProvider);
      if (mounted) context.pop();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        // 42501: RLS 위반 (열리지 않은 지역, 인증 필요 등)
        _error = e.code == '42501'
            ? '지금은 글을 쓸 수 없어요. 내 지역이 아직 열리지 않았거나 교사 인증이 필요할 수 있어요.'
            : '글을 올리지 못했어요. 잠시 후 다시 시도해 주세요.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = '네트워크 상태를 확인하고 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final categories = ref.watch(categoriesProvider(widget.board));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.board.label} 글쓰기')),
      body: SafeArea(
        child: categories.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(child: Text('카테고리를 불러오지 못했어요.')),
          data: (list) {
            final selected = _category ?? list.firstOrNull?.code;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('카테고리', style: textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final category in list)
                          ChoiceChip(
                            label: Text(category.name),
                            selected: selected == category.code,
                            onSelected: (_) =>
                                setState(() => _category = category.code),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      maxLength: 100,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: _titleRequired ? '제목' : '제목 (선택)',
                      ),
                      validator: (value) {
                        if (_titleRequired && (value ?? '').trim().isEmpty) {
                          return '제목을 입력해 주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bodyController,
                      maxLength: 5000,
                      minLines: 8,
                      maxLines: 16,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                        labelText: '내용',
                        helperText: '학생·학부모·동료 교사를 알아볼 수 있는 정보는 쓰지 말아 주세요.',
                        helperMaxLines: 2,
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) return '내용을 입력해 주세요.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_error != null) ...[
                      Text(_error!, style: TextStyle(color: colors.error)),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (_submitting || selected == null)
                            ? null
                            : () => _submit(selected),
                        child: _submitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('올리기'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

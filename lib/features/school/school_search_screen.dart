import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'neis_client.dart';
import 'school.dart';
import 'school_providers.dart';

/// 급식 대시보드용 소속 학교를 검색해서 등록/변경하는 화면.
class SchoolSearchScreen extends ConsumerStatefulWidget {
  const SchoolSearchScreen({super.key});

  @override
  ConsumerState<SchoolSearchScreen> createState() =>
      _SchoolSearchScreenState();
}

class _SchoolSearchScreenState extends ConsumerState<SchoolSearchScreen> {
  final _controller = TextEditingController();
  List<NeisSchool> _results = const [];
  bool _searched = false;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _searched = true;
      _error = null;
    });
    try {
      final results = await ref.read(neisClientProvider).searchSchools(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on NeisApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '검색하지 못했어요. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  Future<void> _select(NeisSchool school) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(schoolRepositoryProvider)
          .setSchool(userId: user.id, school: school);
      ref.invalidate(mySchoolProvider);
      ref.invalidate(todayMealProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('학교를 저장하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('학교 검색')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: '학교 이름',
                  hintText: '예) 울산중앙초등학교',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _loading ? null : _search,
                  ),
                ),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: TextStyle(color: colors.error)),
              ),
            if (!_loading && _error == null && _searched && _results.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('검색 결과가 없어요. 학교 이름을 정확히 입력해 주세요.'),
              ),
            Expanded(
              child: AbsorbPointer(
                absorbing: _saving,
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final school = _results[index];
                    return ListTile(
                      title: Text(school.name),
                      subtitle: Text(
                        [
                          school.officeName,
                          school.address,
                        ].where((s) => s.isNotEmpty).join(' · '),
                      ),
                      onTap: () => _select(school),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

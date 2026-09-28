import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_mark.dart';
import 'board_providers.dart';
import 'models.dart';
import 'post_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key, required this.board});

  final Board board;

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();
  String? _category;

  FeedKey get _key => (board: widget.board, category: _category);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      ref.read(feedProvider(_key).notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(feedProvider(_key));
    await ref.read(feedProvider(_key).future);
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(categoriesProvider(widget.board)).value ?? const [];
    final feed = ref.watch(feedProvider(_key));

    return Scaffold(
      appBar: AppBar(
        leading: const AppMark(),
        leadingWidth: AppMark.leadingWidth,
        titleSpacing: AppMark.titleSpacing,
        title: Text(widget.board.label),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/compose/${widget.board.value}'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('글쓰기'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: '전체',
                  selected: _category == null,
                  onSelected: () => setState(() => _category = null),
                ),
                for (final category in categories)
                  _CategoryChip(
                    label: category.name,
                    selected: _category == category.code,
                    onSelected: () => setState(() => _category = category.code),
                  ),
              ],
            ),
          ),
          Expanded(
            child: feed.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('글을 불러오지 못했어요.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(feedProvider(_key)),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
              data: (state) => RefreshIndicator(
                onRefresh: _refresh,
                child: state.posts.isEmpty
                    ? const _EmptyFeed()
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 4, bottom: 96),
                        itemCount:
                            state.posts.length + (state.loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.posts.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return PostCard(post: state.posts[index]);
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Center(
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onSelected(),
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(
          height: 320,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '아직 글이 없어요.\n첫 이야기를 남겨 보세요!',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

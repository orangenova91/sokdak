import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/util/fuzzy_date.dart';
import '../board/board_providers.dart';
import '../board/models.dart';
import '../profile/profile_providers.dart';

/// 대시보드 하단의 게시판별 최근 글 미리보기.
class BoardPreviewSection extends ConsumerWidget {
  const BoardPreviewSection({super.key, required this.board});

  final Board board;

  String get _boardPath => switch (board) {
    Board.sokdak => '/',
    Board.knowhow => '/knowhow',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final preview = ref.watch(dashboardPreviewProvider(board));

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.go(_boardPath),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Text(board.label, style: textTheme.titleSmall),
                  const Spacer(),
                  Text(
                    '전체',
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: colors.primary),
                ],
              ),
            ),
          ),
          Divider(
            height: 1,
            color: colors.outlineVariant.withValues(alpha: 0.45),
          ),
          preview.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '글을 불러오지 못했어요.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(dashboardPreviewProvider(board)),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
            data: (posts) => posts.isEmpty
                ? InkWell(
                    onTap: () => context.go(_boardPath),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      child: Text(
                        board == Board.knowhow
                            ? '아직 노하우가 없어요. 첫 글을 남겨 보세요.'
                            : '아직 글이 없어요. 이야기를 남겨 보세요.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < posts.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: colors.outlineVariant.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        _PreviewPostRow(post: posts[i]),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPostRow extends ConsumerWidget {
  const _PreviewPostRow({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final categories = ref.watch(categoriesProvider(post.board)).value;
    final categoryName =
        categories?.where((c) => c.code == post.category).firstOrNull?.name ??
        post.category;
    final regionName = ref
        .watch(regionsProvider)
        .value
        ?.where((r) => r.code == post.regionCode)
        .firstOrNull
        ?.name;
    final title = post.title;
    final hasTitle = title != null && title.isNotEmpty;
    final headline = hasTitle ? title : post.body;

    final metaStyle = textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return InkWell(
      onTap: () => context.push('/post/${post.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    categoryName,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (regionName != null) ...[
                  const SizedBox(width: 6),
                  Text(regionName, style: metaStyle),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    headline,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(formatFuzzyDate(post.createdAt), style: metaStyle),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.body,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.favorite_border,
                  size: 14,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 2),
                Text('${post.reactionCount}', style: metaStyle),
                const SizedBox(width: 10),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 2),
                Text('${post.commentCount}', style: metaStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

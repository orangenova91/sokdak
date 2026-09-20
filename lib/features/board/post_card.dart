import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/util/fuzzy_date.dart';
import 'board_providers.dart';
import 'models.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final categories = ref.watch(categoriesProvider(post.board)).value;
    final categoryName =
        categories?.where((c) => c.code == post.category).firstOrNull?.name ??
        post.category;
    final title = post.title;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/post/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                categoryName,
                style: textTheme.labelMedium?.copyWith(color: colors.primary),
              ),
              const SizedBox(height: 6),
              if (title != null && title.isNotEmpty) ...[
                Text(
                  title,
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],
              Text(
                post.body,
                style: textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              DefaultTextStyle(
                style: textTheme.bodySmall!.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.authorNickname,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (post.authorVerified) ...[
                      const SizedBox(width: 2),
                      Icon(Icons.verified, size: 14, color: colors.primary),
                    ],
                    const Text(' · '),
                    Text(formatFuzzyDate(post.createdAt)),
                    const Spacer(),
                    Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Text('${post.reactionCount}'),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Text('${post.commentCount}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

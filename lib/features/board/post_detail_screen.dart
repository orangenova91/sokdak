import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/util/content_guard.dart';
import '../../core/util/fuzzy_date.dart';
import '../auth/auth_providers.dart';
import 'board_providers.dart';
import 'board_repository.dart';
import 'models.dart';
import 'report_sheet.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  Comment? _replyTo;
  bool _sending = false;

  BoardRepository get _repo => ref.read(boardRepositoryProvider);
  String? get _myId => ref.read(currentUserProvider)?.id;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 서버 호출을 실행하고, 실패하면 안내 문구를 띄운다. 성공 여부를 반환한다.
  Future<bool> _attempt(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      if (mounted) _toast('처리하지 못했어요. 잠시 후 다시 시도해 주세요.');
      return false;
    }
  }

  void _refreshAll() {
    ref.invalidate(postDetailProvider(widget.postId));
    ref.invalidate(commentsProvider(widget.postId));
    ref.invalidate(myReactionsProvider(widget.postId));
    ref.invalidate(feedProvider);
  }

  // ---- 글 ----

  Future<void> _toggleReaction(String kind, bool on) async {
    final ok = await _attempt(
      () => _repo.setReaction(postId: widget.postId, kind: kind, on: on),
    );
    if (ok) _refreshAll();
  }

  Future<void> _deletePost() async {
    final yes = await confirm(
      context,
      title: '글 삭제',
      message: '이 글을 삭제할까요? 댓글도 함께 사라져요.',
      confirmLabel: '삭제',
    );
    if (!yes) return;
    final ok = await _attempt(() => _repo.deletePost(widget.postId));
    if (!ok) return;
    ref.invalidate(feedProvider);
    if (mounted) context.pop();
  }

  Future<void> _reportPost() async {
    final reason = await showReportSheet(context);
    if (reason == null) return;
    await _report('post', widget.postId, reason);
    ref.invalidate(feedProvider);
  }

  Future<void> _report(
    String targetType,
    String targetId,
    ReportReason reason,
  ) async {
    try {
      await _repo.report(
        targetType: targetType,
        targetId: targetId,
        reason: reason,
      );
      if (mounted) _toast('신고가 접수됐어요. 확인 후 조치할게요.');
    } on AlreadyReportedException {
      if (mounted) _toast('이미 신고한 내용이에요.');
    } catch (_) {
      if (mounted) _toast('신고하지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
    ref.invalidate(commentsProvider(widget.postId));
  }

  /// 작성자를 차단한다. 글 작성자를 차단했으면 목록으로 돌아간다.
  Future<void> _block(String userId, {required bool leave}) async {
    final yes = await confirm(
      context,
      title: '작성자 차단',
      message:
          '이 작성자의 글과 댓글이 더 이상 보이지 않아요. '
          '차단은 내 정보 > 차단한 사용자에서 풀 수 있어요.',
      confirmLabel: '차단',
    );
    if (!yes) return;
    final ok = await _attempt(() => _repo.blockUser(userId));
    if (!ok) return;
    ref.invalidate(feedProvider);
    ref.invalidate(commentsProvider(widget.postId));
    if (!mounted) return;
    _toast('차단했어요.');
    if (leave) context.pop();
  }

  // ---- 댓글 ----

  Future<void> _sendComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty || _sending) return;

    final guardMessage = ContentGuard.check(body);
    if (guardMessage != null) {
      _toast(guardMessage);
      return;
    }

    setState(() => _sending = true);
    final replyTo = _replyTo;
    final ok = await _attempt(
      () => _repo.createComment(
        postId: widget.postId,
        body: body,
        // 대댓글은 한 단계까지만: 답글에 답해도 원 댓글 아래에 붙인다.
        parentId: replyTo?.parentId ?? replyTo?.id,
      ),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (!ok) return;
    _commentController.clear();
    setState(() => _replyTo = null);
    _refreshAll();
  }

  Future<void> _toggleCommentLike(Comment comment, bool on) async {
    final ok = await _attempt(
      () => _repo.setCommentLike(commentId: comment.id, on: on),
    );
    if (ok) ref.invalidate(commentsProvider(widget.postId));
  }

  Future<void> _deleteComment(Comment comment) async {
    final yes = await confirm(
      context,
      title: '댓글 삭제',
      message: '이 댓글을 삭제할까요? 달린 답글도 함께 사라져요.',
      confirmLabel: '삭제',
    );
    if (!yes) return;
    final ok = await _attempt(() => _repo.deleteComment(comment.id));
    if (ok) _refreshAll();
  }

  Future<void> _onCommentMenu(Comment comment, String action) async {
    switch (action) {
      case 'delete':
        await _deleteComment(comment);
      case 'report':
        final reason = await showReportSheet(context);
        if (reason != null) await _report('comment', comment.id, reason);
      case 'block':
        await _block(comment.authorId, leave: false);
    }
  }

  // ---- 화면 ----

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final post = postAsync.value;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (post != null)
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'delete':
                    _deletePost();
                  case 'report':
                    _reportPost();
                  case 'block':
                    _block(post.authorId, leave: true);
                }
              },
              itemBuilder: (context) => post.authorId == _myId
                  ? const [PopupMenuItem(value: 'delete', child: Text('삭제'))]
                  : const [
                      PopupMenuItem(value: 'report', child: Text('신고')),
                      PopupMenuItem(value: 'block', child: Text('작성자 차단')),
                    ],
            ),
        ],
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('글을 불러오지 못했어요.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(postDetailProvider(widget.postId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (post) => post == null
            ? const Center(child: Text('삭제되었거나 볼 수 없는 글이에요.'))
            : _buildBody(post),
      ),
    );
  }

  Widget _buildBody(Post post) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _PostHeader(post: post, isMine: post.authorId == _myId),
              if (post.isHidden) ...[
                const SizedBox(height: 12),
                _HiddenNotice(),
              ],
              const SizedBox(height: 16),
              _ReactionBar(
                post: post,
                onToggle: _toggleReaction,
                mine:
                    ref.watch(myReactionsProvider(widget.postId)).value ??
                    const {},
              ),
              const Divider(height: 32),
              _buildComments(post),
            ],
          ),
        ),
        if (!post.isHidden) _buildComposer(),
      ],
    );
  }

  Widget _buildComments(Post post) {
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final textTheme = Theme.of(context).textTheme;

    return commentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const Text('댓글을 불러오지 못했어요.'),
      data: (data) {
        final ids = data.comments.map((c) => c.id).toSet();
        // 부모 댓글이 숨김/차단으로 안 보이면 답글을 최상위로 올려 사라지지 않게 한다.
        final topLevel = data.comments
            .where((c) => c.parentId == null || !ids.contains(c.parentId))
            .toList();

        Widget tile(Comment c, {required bool isReply}) => _CommentTile(
          comment: c,
          isReply: isReply,
          isPostAuthor: c.authorId == post.authorId,
          isMine: c.authorId == _myId,
          liked: data.likedIds.contains(c.id),
          onLike: () => _toggleCommentLike(c, !data.likedIds.contains(c.id)),
          onReply: post.isHidden ? null : () => setState(() => _replyTo = c),
          onMenu: (action) => _onCommentMenu(c, action),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('댓글 ${data.comments.length}', style: textTheme.titleSmall),
            const SizedBox(height: 8),
            if (data.comments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('첫 댓글을 남겨 보세요.')),
              ),
            for (final comment in topLevel) ...[
              tile(comment, isReply: false),
              for (final reply in data.comments.where(
                (c) => c.parentId == comment.id,
              ))
                tile(reply, isReply: true),
            ],
          ],
        );
      },
    );
  }

  Widget _buildComposer() {
    final colors = Theme.of(context).colorScheme;
    final replyTo = _replyTo;

    return Material(
      elevation: 4,
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (replyTo != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${replyTo.authorNickname}님에게 답글',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _replyTo = null),
                    ),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLength: 1000,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: '댓글을 입력하세요',
                        counterText: '',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _sendComment,
                    icon: _sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends ConsumerWidget {
  const _PostHeader({required this.post, required this.isMine});

  final Post post;
  final bool isMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final categories = ref.watch(categoriesProvider(post.board)).value;
    final categoryName =
        categories?.where((c) => c.code == post.category).firstOrNull?.name ??
        post.category;
    final title = post.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryName,
          style: textTheme.labelMedium?.copyWith(color: colors.primary),
        ),
        const SizedBox(height: 8),
        if (title != null && title.isNotEmpty) ...[
          Text(title, style: textTheme.titleLarge),
          const SizedBox(height: 8),
        ],
        DefaultTextStyle(
          style: textTheme.bodySmall!.copyWith(color: colors.onSurfaceVariant),
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
              if (isMine) const Text(' (나)'),
              const Text(' · '),
              Text(formatFuzzyDate(post.createdAt)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SelectableText(post.body, style: textTheme.bodyLarge),
      ],
    );
  }
}

class _HiddenNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '신고가 여러 건 접수되어 다른 사용자에게는 보이지 않는 글이에요.',
        style: TextStyle(color: colors.onErrorContainer),
      ),
    );
  }
}

class _ReactionBar extends StatelessWidget {
  const _ReactionBar({
    required this.post,
    required this.onToggle,
    required this.mine,
  });

  final Post post;
  final void Function(String kind, bool on) onToggle;
  final Set<String> mine;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final reaction in post.board.reactions)
          FilterChip(
            label: Text(reaction.label),
            selected: mine.contains(reaction.kind),
            onSelected: (on) => onToggle(reaction.kind, on),
          ),
        Text(
          '공감 ${post.reactionCount}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isReply,
    required this.isPostAuthor,
    required this.isMine,
    required this.liked,
    required this.onLike,
    required this.onReply,
    required this.onMenu,
  });

  final Comment comment;
  final bool isReply;
  final bool isPostAuthor;
  final bool isMine;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback? onReply;
  final void Function(String action) onMenu;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final subtle = textTheme.bodySmall!.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Padding(
      padding: EdgeInsets.only(left: isReply ? 24 : 0, top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isReply)
            Padding(
              padding: const EdgeInsets.only(right: 6, top: 2),
              child: Icon(
                Icons.subdirectory_arrow_right,
                size: 16,
                color: colors.outline,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.authorNickname,
                        style: textTheme.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (comment.authorVerified) ...[
                      const SizedBox(width: 2),
                      Icon(Icons.verified, size: 14, color: colors.primary),
                    ],
                    if (isPostAuthor)
                      Text(
                        ' · 글쓴이',
                        style: subtle.copyWith(color: colors.primary),
                      ),
                    if (isMine) Text(' · 나', style: subtle),
                    Text(
                      ' · ${formatFuzzyDate(comment.createdAt)}',
                      style: subtle,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.body, style: textTheme.bodyMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    InkWell(
                      onTap: onLike,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              liked ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: liked
                                  ? colors.error
                                  : colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text('${comment.likeCount}', style: subtle),
                          ],
                        ),
                      ),
                    ),
                    if (onReply != null) ...[
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: onReply,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('답글', style: subtle),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            iconSize: 18,
            padding: EdgeInsets.zero,
            onSelected: onMenu,
            itemBuilder: (context) => isMine
                ? const [PopupMenuItem(value: 'delete', child: Text('삭제'))]
                : const [
                    PopupMenuItem(value: 'report', child: Text('신고')),
                    PopupMenuItem(value: 'block', child: Text('작성자 차단')),
                  ],
          ),
        ],
      ),
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

/// 이미 신고한 대상을 다시 신고했을 때 던진다.
class AlreadyReportedException implements Exception {
  const AlreadyReportedException();
}

class BoardRepository {
  BoardRepository(this._client);

  final SupabaseClient _client;

  // profiles 와의 관계가 공감/좋아요 테이블을 거치는 다대다로도 존재하므로,
  // 작성자 FK를 명시하지 않으면 PostgREST가 조인 대상을 특정하지 못한다.
  static const _postSelect =
      '*, profiles!posts_author_id_fkey(nickname, is_verified)';
  static const _commentSelect =
      '*, profiles!comments_author_id_fkey(nickname, is_verified)';

  Future<List<Category>> fetchCategories(Board board) async {
    final rows = await _client
        .from('categories')
        .select()
        .eq('board', board.value)
        .order('sort_order', ascending: true);
    return rows.map(Category.fromJson).toList();
  }

  // ---- 글 ----

  Future<List<Post>> fetchPosts({
    required Board board,
    required String regionCode,
    String? category,
    DateTime? before,
    int limit = 20,
  }) async {
    var query = _client
        .from('posts')
        .select(_postSelect)
        .eq('board', board.value)
        .eq('region_code', regionCode)
        .eq('is_hidden', false);
    if (category != null) query = query.eq('category', category);
    if (before != null) {
      query = query.lt('created_at', before.toUtc().toIso8601String());
    }
    final rows = await query.order('created_at', ascending: false).limit(limit);
    return rows.map(Post.fromJson).toList();
  }

  /// 삭제되었거나 볼 수 없는(숨김/차단) 글이면 null.
  Future<Post?> fetchPost(String id) async {
    final row = await _client
        .from('posts')
        .select(_postSelect)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Post.fromJson(row);
  }

  Future<void> createPost({
    required Board board,
    required String category,
    required String regionCode,
    required String? title,
    required String body,
  }) async {
    await _client.from('posts').insert({
      'board': board.value,
      'category': category,
      'region_code': regionCode,
      'title': title,
      'body': body,
    });
  }

  Future<void> deletePost(String id) async {
    await _client.from('posts').delete().eq('id', id);
  }

  // ---- 공감 ----

  Future<Set<String>> fetchMyReactions(String postId) async {
    final rows = await _client
        .from('post_reactions')
        .select('kind')
        .eq('post_id', postId);
    return rows.map((row) => row['kind'] as String).toSet();
  }

  Future<void> setReaction({
    required String postId,
    required String kind,
    required bool on,
  }) async {
    if (on) {
      await _client.from('post_reactions').insert({
        'post_id': postId,
        'kind': kind,
      });
    } else {
      await _client
          .from('post_reactions')
          .delete()
          .eq('post_id', postId)
          .eq('kind', kind);
    }
  }

  // ---- 댓글 ----

  Future<CommentsData> fetchComments(String postId) async {
    final rows = await _client
        .from('comments')
        .select(_commentSelect)
        .eq('post_id', postId)
        .eq('is_hidden', false)
        .order('created_at', ascending: true);
    final comments = rows.map(Comment.fromJson).toList();

    var likedIds = <String>{};
    if (comments.isNotEmpty) {
      final liked = await _client
          .from('comment_likes')
          .select('comment_id')
          .inFilter('comment_id', comments.map((c) => c.id).toList());
      likedIds = liked.map((row) => row['comment_id'] as String).toSet();
    }
    return CommentsData(comments: comments, likedIds: likedIds);
  }

  Future<void> createComment({
    required String postId,
    required String body,
    String? parentId,
  }) async {
    await _client.from('comments').insert({
      'post_id': postId,
      'body': body,
      'parent_id': parentId,
    });
  }

  Future<void> deleteComment(String id) async {
    await _client.from('comments').delete().eq('id', id);
  }

  Future<void> setCommentLike({
    required String commentId,
    required bool on,
  }) async {
    if (on) {
      await _client.from('comment_likes').insert({'comment_id': commentId});
    } else {
      await _client.from('comment_likes').delete().eq('comment_id', commentId);
    }
  }

  // ---- 신고 / 차단 ----

  Future<void> report({
    required String targetType,
    required String targetId,
    required ReportReason reason,
  }) async {
    try {
      await _client.from('reports').insert({
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason.value,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const AlreadyReportedException();
      rethrow;
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _client.from('blocks').insert({'blocked_id': userId});
    } on PostgrestException catch (e) {
      // 이미 차단한 사용자면 그대로 성공으로 본다.
      if (e.code != '23505') rethrow;
    }
  }

  Future<void> unblockUser(String userId) async {
    await _client.from('blocks').delete().eq('blocked_id', userId);
  }

  Future<List<BlockedUser>> fetchBlockedUsers() async {
    final rows = await _client
        .from('blocks')
        .select('blocked_id, profiles!blocks_blocked_id_fkey(nickname)')
        .order('created_at', ascending: false);
    return rows.map((row) {
      final profile = row['profiles'] as Map<String, dynamic>?;
      return BlockedUser(
        userId: row['blocked_id'] as String,
        nickname: profile?['nickname'] as String? ?? '알 수 없음',
      );
    }).toList();
  }

  // ---- 계정 ----

  /// 서버에서 계정과 모든 작성 내용을 삭제한다.
  Future<void> deleteAccount() async {
    await _client.rpc('delete_my_account');
    // 서버에서 이미 사라진 사용자이므로 서버 호출 없이 로컬 세션만 정리한다.
    await _client.auth.signOut(scope: SignOutScope.local);
  }
}

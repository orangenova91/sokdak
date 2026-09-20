enum Board {
  sokdak('sokdak', '속닥방'),
  knowhow('knowhow', '노하우방');

  const Board(this.value, this.label);

  /// DB `posts.board` 에 저장되는 값
  final String value;
  final String label;

  static Board fromValue(String value) {
    return Board.values.firstWhere(
      (board) => board.value == value,
      orElse: () => Board.sokdak,
    );
  }

  /// 게시판별로 쓸 수 있는 공감 종류 (DB `post_reactions.kind`)
  List<({String kind, String label})> get reactions {
    return switch (this) {
      Board.sokdak => const [
        (kind: 'cheer', label: '힘내요'),
        (kind: 'me_too', label: '나도 그래요'),
        (kind: 'like', label: '좋아요'),
      ],
      Board.knowhow => const [(kind: 'like', label: '도움돼요')],
    };
  }
}

class Category {
  const Category({required this.code, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(code: json['code'] as String, name: json['name'] as String);
  }

  final String code;
  final String name;
}

class Post {
  const Post({
    required this.id,
    required this.board,
    required this.category,
    required this.regionCode,
    required this.authorId,
    required this.authorNickname,
    required this.authorVerified,
    required this.title,
    required this.body,
    required this.isHidden,
    required this.commentCount,
    required this.reactionCount,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final author = json['profiles'] as Map<String, dynamic>?;
    return Post(
      id: json['id'] as String,
      board: Board.fromValue(json['board'] as String),
      category: json['category'] as String,
      regionCode: json['region_code'] as String,
      authorId: json['author_id'] as String,
      authorNickname: author?['nickname'] as String? ?? '알 수 없음',
      authorVerified: author?['is_verified'] as bool? ?? false,
      title: json['title'] as String?,
      body: json['body'] as String,
      isHidden: json['is_hidden'] as bool,
      commentCount: json['comment_count'] as int,
      reactionCount: json['reaction_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final Board board;
  final String category;
  final String regionCode;
  final String authorId;
  final String authorNickname;
  final bool authorVerified;
  final String? title;
  final String body;
  final bool isHidden;
  final int commentCount;
  final int reactionCount;
  final DateTime createdAt;
}

class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.parentId,
    required this.authorId,
    required this.authorNickname,
    required this.authorVerified,
    required this.body,
    required this.likeCount,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final author = json['profiles'] as Map<String, dynamic>?;
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      parentId: json['parent_id'] as String?,
      authorId: json['author_id'] as String,
      authorNickname: author?['nickname'] as String? ?? '알 수 없음',
      authorVerified: author?['is_verified'] as bool? ?? false,
      body: json['body'] as String,
      likeCount: json['like_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String postId;
  final String? parentId;
  final String authorId;
  final String authorNickname;
  final bool authorVerified;
  final String body;
  final int likeCount;
  final DateTime createdAt;
}

/// 댓글 목록과, 그중 내가 좋아요를 누른 댓글 id
class CommentsData {
  const CommentsData({required this.comments, required this.likedIds});

  final List<Comment> comments;
  final Set<String> likedIds;
}

class BlockedUser {
  const BlockedUser({required this.userId, required this.nickname});

  final String userId;
  final String nickname;
}

enum ReportReason {
  abuse('abuse', '욕설·비하'),
  privacy('privacy', '개인정보 노출'),
  defamation('defamation', '명예훼손'),
  spam('spam', '스팸·광고'),
  other('other', '기타');

  const ReportReason(this.value, this.label);

  final String value;
  final String label;
}

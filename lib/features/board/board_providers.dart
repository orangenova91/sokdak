import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_provider.dart';
import '../auth/auth_providers.dart';
import '../profile/profile_providers.dart';
import 'board_repository.dart';
import 'models.dart';

final boardRepositoryProvider = Provider<BoardRepository>((ref) {
  return BoardRepository(ref.watch(supabaseProvider));
});

final categoriesProvider = FutureProvider.family<List<Category>, Board>((
  ref,
  board,
) async {
  // 로그아웃/재로그인 시 다시 불러오도록 사용자에 의존시킨다.
  ref.watch(currentUserProvider);
  return ref.watch(boardRepositoryProvider).fetchCategories(board);
});

// ---- 피드 ----

/// 피드 하나를 식별하는 키. category가 null이면 "전체".
typedef FeedKey = ({Board board, String? category});

class FeedState {
  const FeedState({
    required this.posts,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<Post> posts;
  final bool hasMore;
  final bool loadingMore;

  FeedState copyWith({List<Post>? posts, bool? hasMore, bool? loadingMore}) {
    return FeedState(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

class FeedController extends AsyncNotifier<FeedState> {
  FeedController(this.key);

  final FeedKey key;

  static const pageSize = 20;

  Future<List<Post>> _fetch({DateTime? before}) async {
    final profile = await ref.read(myProfileProvider.future);
    if (profile == null) return const [];
    return ref
        .read(boardRepositoryProvider)
        .fetchPosts(
          board: key.board,
          regionCode: profile.regionCode,
          category: key.category,
          before: before,
          limit: pageSize,
        );
  }

  @override
  Future<FeedState> build() async {
    final posts = await _fetch();
    return FeedState(posts: posts, hasMore: posts.length == pageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final more = await _fetch(before: current.posts.last.createdAt);
      state = AsyncData(
        FeedState(
          posts: [...current.posts, ...more],
          hasMore: more.length == pageSize,
        ),
      );
    } catch (_) {
      // 다음 스크롤에서 다시 시도할 수 있도록 로딩 표시만 끈다.
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}

final feedProvider =
    AsyncNotifierProvider.family<FeedController, FeedState, FeedKey>(
      FeedController.new,
    );

// ---- 글 상세 ----

final postDetailProvider = FutureProvider.autoDispose.family<Post?, String>((
  ref,
  postId,
) {
  return ref.watch(boardRepositoryProvider).fetchPost(postId);
});

final myReactionsProvider = FutureProvider.autoDispose
    .family<Set<String>, String>((ref, postId) {
      return ref.watch(boardRepositoryProvider).fetchMyReactions(postId);
    });

final commentsProvider = FutureProvider.autoDispose
    .family<CommentsData, String>((ref, postId) {
      return ref.watch(boardRepositoryProvider).fetchComments(postId);
    });

// ---- 차단 ----

final blockedUsersProvider = FutureProvider.autoDispose<List<BlockedUser>>((
  ref,
) {
  return ref.watch(boardRepositoryProvider).fetchBlockedUsers();
});

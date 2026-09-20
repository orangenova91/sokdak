import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_providers.dart';
import '../../features/board/compose_screen.dart';
import '../../features/board/feed_screen.dart';
import '../../features/board/models.dart';
import '../../features/board/post_detail_screen.dart';
import '../../features/me/blocked_users_screen.dart';
import '../../features/me/legal_screen.dart';
import '../../features/me/legal_texts.dart';
import '../../features/me/my_page_screen.dart';
import '../../features/onboarding/profile_setup_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/profile/profile_providers.dart';
import '../../features/system/system_screens.dart';
import '../config/env.dart';
import 'main_shell.dart';

/// 로그인/프로필 상태에 따라 갈 수 있는 화면이 정해진다.
/// 온보딩 전용 경로에 있는 사용자가 프로필을 갖추면 홈으로 보낸다.
const _gatedPaths = {
  '/setup-required',
  '/welcome',
  '/splash',
  '/profile-setup',
  '/error',
};

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);

  // Env 미설정 시 Supabase가 초기화되지 않으므로 인증 프로바이더를 건드리지 않는다.
  if (Env.isConfigured) {
    ref.listen(currentUserProvider, (_, _) => refresh.value++);
    ref.listen(myProfileProvider, (_, _) => refresh.value++);
  }

  String? redirect(GoRouterState state) {
    final location = state.matchedLocation;
    String? goTo(String target) => location == target ? null : target;

    if (!Env.isConfigured) return goTo('/setup-required');

    // 약관은 가입 전에도 볼 수 있어야 한다.
    if (location.startsWith('/legal/')) return null;

    if (ref.read(currentUserProvider) == null) return goTo('/welcome');

    final profile = ref.read(myProfileProvider);
    if (profile.hasError && !profile.hasValue) return goTo('/error');
    if (!profile.hasValue) return goTo('/splash');
    if (profile.requireValue == null) return goTo('/profile-setup');

    return _gatedPaths.contains(location) ? '/' : null;
  }

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) => redirect(state),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const FeedScreen(board: Board.sokdak),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/knowhow',
                builder: (context, state) =>
                    const FeedScreen(board: Board.knowhow),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (context, state) => const MyPageScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/compose/:board',
        builder: (context, state) => ComposeScreen(
          board: Board.fromValue(state.pathParameters['board']!),
        ),
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) =>
            PostDetailScreen(postId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/blocked',
        builder: (context, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: '/legal/:type',
        builder: (context, state) => LegalScreen(
          document: withContactSection(
            state.pathParameters['type'] == 'privacy'
                ? privacyPolicy
                : termsOfService,
          ),
        ),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/error',
        builder: (context, state) => const ProfileErrorScreen(),
      ),
      GoRoute(
        path: '/setup-required',
        builder: (context, state) => const SetupRequiredScreen(),
      ),
    ],
  );
});

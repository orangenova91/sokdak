import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_info.dart';
import '../../core/supabase/supabase_provider.dart';
import '../board/board_providers.dart';
import '../board/report_sheet.dart';
import '../profile/profile_providers.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final yes = await confirm(
      context,
      title: '계정 삭제',
      message: '계정과 내가 쓴 글, 댓글, 공감이 모두 삭제되고 되돌릴 수 없어요. 정말 삭제할까요?',
      confirmLabel: '삭제',
    );
    if (!yes) return;
    try {
      // 삭제되면 로그인 상태가 풀려 라우터가 환영 화면으로 보낸다.
      await ref.read(boardRepositoryProvider).deleteAccount();
      ref.invalidate(feedProvider);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계정을 삭제하지 못했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final profile = ref.watch(myProfileProvider).value;
    final regions = ref.watch(regionsProvider).value;
    final regionName = regions
        ?.where((r) => r.code == profile?.regionCode)
        .firstOrNull
        ?.name;

    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: ListView(
        children: [
          if (profile != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.nickname, style: textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    [?regionName, profile.schoolLevel.label].join(' · '),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.isVerified ? '인증된 교사' : '교사 인증 전',
                    style: textTheme.bodySmall?.copyWith(
                      color: profile.isVerified
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('차단한 사용자'),
            onTap: () => context.push('/blocked'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('이용약관'),
            onTap: () => context.push('/legal/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보 처리방침'),
            onTap: () => context.push('/legal/privacy'),
          ),
          if (AppInfo.contactEmail.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('문의·신고'),
              subtitle: const Text(AppInfo.contactEmail),
            ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.delete_outline, color: colors.error),
            title: Text('계정 삭제', style: TextStyle(color: colors.error)),
            onTap: () => _deleteAccount(context, ref),
          ),
          if (kDebugMode)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('개발용: 로그아웃 (계정은 서버에 남음)'),
              onTap: () => ref.read(supabaseProvider).auth.signOut(),
            ),
        ],
      ),
    );
  }
}

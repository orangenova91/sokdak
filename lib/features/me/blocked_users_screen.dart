import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../board/board_providers.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('차단한 사용자')),
      body: blocked.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: OutlinedButton(
            onPressed: () => ref.invalidate(blockedUsersProvider),
            child: const Text('불러오지 못했어요. 다시 시도'),
          ),
        ),
        data: (users) => users.isEmpty
            ? const Center(child: Text('차단한 사용자가 없어요.'))
            : ListView(
                children: [
                  for (final user in users)
                    ListTile(
                      title: Text(user.nickname),
                      trailing: TextButton(
                        onPressed: () async {
                          await ref
                              .read(boardRepositoryProvider)
                              .unblockUser(user.userId);
                          ref.invalidate(blockedUsersProvider);
                          // 차단이 풀리면 그 사용자의 글이 다시 보여야 한다.
                          ref.invalidate(feedProvider);
                        },
                        child: const Text('차단 해제'),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/profile_providers.dart';
import 'region_signup.dart';

class RegionSignupScreen extends ConsumerWidget {
  const RegionSignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(regionSignupStatsProvider);
    final myRegion = ref.watch(myProfileProvider).value?.regionCode;

    return Scaffold(
      appBar: AppBar(title: const Text('지역별 가입 통계')),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: OutlinedButton(
            onPressed: () => ref.invalidate(regionSignupStatsProvider),
            child: const Text('불러오지 못했어요. 다시 시도'),
          ),
        ),
        data: (list) => _SignupStatsBody(stats: list, myRegionCode: myRegion),
      ),
    );
  }
}

class _SignupStatsBody extends StatelessWidget {
  const _SignupStatsBody({required this.stats, required this.myRegionCode});

  final List<RegionSignupStat> stats;
  final String? myRegionCode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final arranged = arrangeRegionSignupStats(
      stats,
      myRegionCode: myRegionCode,
    );
    final year = stats.firstOrNull?.statsYear;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          year == null
              ? '각 지역을 선택한 계정 수를 교육통계의 교원 수로 나눈 값이에요.'
              : '각 지역을 선택한 계정 수를 $year년 교육통계의 교원 수로 나눈 값이에요.',
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        for (final stat in arranged) ...[
          _StatCard(stat: stat, mine: stat.regionCode == myRegionCode),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat, required this.mine});

  final RegionSignupStat stat;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final background = mine
        ? colors.primaryContainer
        : colors.surfaceContainerLow;
    final foreground = mine ? colors.onPrimaryContainer : colors.onSurface;
    final muted = mine
        ? colors.onPrimaryContainer.withValues(alpha: 0.8)
        : colors.onSurfaceVariant;
    final rate = stat.rate;

    return Card(
      elevation: 0,
      color: background,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  stat.regionName,
                  style: textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 8),
                  Text(
                    '내 지역',
                    style: textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ],
                const Spacer(),
                Text(
                  rate == null ? '집계 중' : formatSignupRate(rate),
                  style: textTheme.labelLarge?.copyWith(color: foreground),
                ),
              ],
            ),
            if (rate != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: rate,
                  minHeight: 8,
                  backgroundColor: mine
                      ? colors.onPrimaryContainer.withValues(alpha: 0.12)
                      : colors.surfaceContainerHighest,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${formatGrouped(stat.signupCount!)}명 / ${formatGrouped(stat.teacherCount)}명',
                style: textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

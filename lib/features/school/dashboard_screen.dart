import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import 'school.dart';
import 'school_providers.dart';
import 'week_calendar.dart';

/// 하단 탭의 "대시보드" 화면. 등록한 학교의 학사일정과 오늘 급식을 보여준다.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.isNeisConfigured) {
      return const Scaffold(
        appBar: _DashboardAppBar(),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('급식 정보 기능이 아직 설정되지 않았어요.'),
          ),
        ),
      );
    }

    final school = ref.watch(mySchoolProvider);

    return Scaffold(
      appBar: const _DashboardAppBar(),
      body: SafeArea(
        child: school.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            onRetry: () => ref.invalidate(mySchoolProvider),
          ),
          data: (school) =>
              school == null ? const _NoSchoolState() : _SchoolDashboard(school: school),
        ),
      ),
    );
  }
}

class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DashboardAppBar();

  @override
  Widget build(BuildContext context) => AppBar(
    title: const Text('대시보드'),
    actions: [
      IconButton(
        onPressed: () => context.push('/school-search'),
        icon: const Icon(Icons.school_outlined),
        tooltip: '학교 설정',
      ),
    ],
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('정보를 불러오지 못했어요.'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _NoSchoolState extends StatelessWidget {
  const _NoSchoolState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 480,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_outlined, size: 48, color: colors.primary),
                  const SizedBox(height: 16),
                  Text(
                    '학교를 등록하면\n오늘 급식을 볼 수 있어요',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.push('/school-search'),
                    child: const Text('학교 등록하기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SchoolDashboard extends ConsumerWidget {
  const _SchoolDashboard({required this.school});

  final SchoolSelection school;

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(todayMealProvider);
    ref.invalidate(scheduleEventsProvider);
    await Future.wait([
      ref.read(todayMealProvider.future),
      ref.read(scheduleEventsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final meals = ref.watch(todayMealProvider);

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text(school.schoolName, style: textTheme.titleLarge),
          const SizedBox(height: 20),
          Text('학사일정', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          const WeekCalendarCard(),
          const SizedBox(height: 28),
          Text('오늘 급식', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          meals.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Text(
                    '급식 정보를 불러오지 못했어요.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => ref.invalidate(todayMealProvider),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
            data: (meals) => meals.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      '오늘은 급식이 없어요.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final meal in meals)
                        Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.mealName,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                for (final item in meal.menuItems)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(item, style: textTheme.bodyMedium),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

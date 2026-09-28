import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/widgets/app_mark.dart';
import '../board/board_providers.dart';
import '../board/models.dart';
import '../weather/weather_chip.dart';
import '../weather/weather_providers.dart';
import 'board_preview_section.dart';
import 'school.dart';
import 'school_providers.dart';
import 'week_calendar.dart';
import 'week_meals_sheet.dart';

const _weekdayNames = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];

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
              school == null ? const _NoSchoolState() : const _SchoolDashboard(),
        ),
      ),
    );
  }
}

class _DashboardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _DashboardAppBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolName = ref.watch(mySchoolProvider).value?.schoolName;
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      leading: const AppMark(),
      leadingWidth: AppMark.leadingWidth,
      titleSpacing: AppMark.titleSpacing,
      title: const Text('대시보드'),
      actions: [
        if (schoolName != null)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  schoolName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          ),
        IconButton(
          onPressed: () => context.push('/school-search'),
          icon: const Icon(Icons.account_balance_outlined),
          tooltip: '학교 설정',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel =
        '${now.month}월 ${now.day}일 ${_weekdayNames[now.weekday - 1]}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dateLabel,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const WeatherChip(),
        ],
      ),
    );
  }
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        const _DashboardHeader(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_outlined,
                size: 48,
                color: colors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '학교를 등록하면\n학사일정과 급식 정보를 볼 수 있어요',
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
        const BoardPreviewSection(board: Board.sokdak),
        const SizedBox(height: 24),
        const BoardPreviewSection(board: Board.knowhow),
      ],
    );
  }
}

class _SchoolDashboard extends ConsumerWidget {
  const _SchoolDashboard();

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(todayMealProvider);
    ref.invalidate(weekMealsProvider);
    ref.invalidate(scheduleEventsProvider);
    ref.invalidate(dashboardPreviewProvider(Board.sokdak));
    ref.invalidate(dashboardPreviewProvider(Board.knowhow));
    ref.invalidate(currentWeatherProvider);
    await Future.wait([
      ref.read(todayMealProvider.future),
      ref.read(scheduleEventsProvider.future),
      ref.read(dashboardPreviewProvider(Board.sokdak).future),
      ref.read(dashboardPreviewProvider(Board.knowhow).future),
      ref.read(currentWeatherProvider.future),
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          const _DashboardHeader(),
          const WeekCalendarCard(),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => showWeekMealsSheet(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    '오늘 급식',
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '일주일',
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          meals.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '급식 정보를 불러오지 못했어요.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(todayMealProvider),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
            data: (meals) => _TodayMealsSection(
              meals: meals,
              onOpenWeek: () => showWeekMealsSheet(context),
            ),
          ),
          const SizedBox(height: 28),
          const BoardPreviewSection(board: Board.sokdak),
          const SizedBox(height: 24),
          const BoardPreviewSection(board: Board.knowhow),
        ],
      ),
    );
  }
}

class _TodayMealsSection extends StatelessWidget {
  const _TodayMealsSection({required this.meals, required this.onOpenWeek});

  final List<MealInfo> meals;
  final VoidCallback onOpenWeek;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    if (meals.isEmpty) {
      return Card(
        elevation: 0,
        color: colors.surfaceContainerLow,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpenWeek,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Text(
              '오늘은 급식이 없어요.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final meal in meals)
          Card(
            elevation: 0,
            color: colors.surfaceContainerLow,
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onOpenWeek,
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
                    Text(
                      meal.menuItems.join(' · '),
                      style: textTheme.bodyMedium?.copyWith(height: 1.4),
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

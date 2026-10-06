import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'school.dart';
import 'school_providers.dart';

const _weekdayShort = ['일', '월', '화', '수', '목', '금', '토'];

/// 이번 주(월~금) 급식을 보여주는 바텀시트.
Future<void> showWeekMealsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => const _WeekMealsSheet(),
  );
}

class _WeekMealsSheet extends ConsumerWidget {
  const _WeekMealsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final meals = ref.watch(weekMealsProvider);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final weekStart = mondayOfWeek(DateTime.now());
    final weekEnd = weekStart.add(const Duration(days: 4));
    final rangeLabel = weekEnd.year == weekStart.year
        ? '${weekStart.month}월 ${weekStart.day}일 – ${weekEnd.month}월 ${weekEnd.day}일'
        : '${weekStart.year}.${weekStart.month}.${weekStart.day} – '
              '${weekEnd.year}.${weekEnd.month}.${weekEnd.day}';

    return SizedBox(
      height: maxHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이번 주 급식', style: textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  rangeLabel,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.5)),
          Expanded(
            child: meals.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restaurant_outlined,
                        size: 40,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '급식 정보를 불러오지 못했어요.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.invalidate(weekMealsProvider),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (days) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                itemCount: days.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _DayMealsCard(day: days[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayMealsCard extends StatelessWidget {
  const _DayMealsCard({required this.day});

  final DailyMeals day;

  Color _weekdayColor(ColorScheme colors, int weekdayIndex) {
    if (weekdayIndex == 0) return colors.error;
    if (weekdayIndex == 6) return colors.tertiary;
    return colors.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final isToday =
        day.date.year == today.year &&
        day.date.month == today.month &&
        day.date.day == today.day;
    final weekdayIndex = day.date.weekday % 7;
    final weekdayColor = _weekdayColor(colors, weekdayIndex);

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isToday ? colors.primaryContainer : colors.surfaceContainerHigh,
            child: Row(
              children: [
                Text(
                  '${day.date.day}',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isToday ? colors.onPrimaryContainer : colors.onSurface,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _weekdayShort[weekdayIndex],
                      style: textTheme.labelLarge?.copyWith(
                        color: isToday
                            ? colors.onPrimaryContainer
                            : weekdayColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${day.date.month}월',
                      style: textTheme.bodySmall?.copyWith(
                        color: isToday
                            ? colors.onPrimaryContainer.withValues(alpha: 0.8)
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (isToday) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '오늘',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: day.meals.isEmpty
                ? Text(
                    '급식이 없어요',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < day.meals.length; i++) ...[
                        if (i > 0) ...[
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            color: colors.outlineVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _MealBlock(meal: day.meals[i]),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MealBlock extends StatelessWidget {
  const _MealBlock({required this.meal});

  final MealInfo meal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          meal.mealName,
          style: textTheme.labelLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          meal.menuItems.join(' · '),
          style: textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
      ],
    );
  }
}

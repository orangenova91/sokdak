import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import 'school.dart';
import 'school_providers.dart';

/// 속닥방(홈 피드) 상단에 오늘 급식을 보여주는 카드.
/// NEIS 키가 설정돼 있지 않으면(로컬 개발 등) 아무것도 그리지 않는다.
class MealDashboardCard extends ConsumerWidget {
  const MealDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.isNeisConfigured) return const SizedBox.shrink();

    final school = ref.watch(mySchoolProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: school.when(
            loading: () => const SizedBox(
              height: 20,
              child: Center(
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (school) => school == null
                ? const _NoSchoolContent()
                : _SchoolMealContent(school: school),
          ),
        ),
      ),
    );
  }
}

class _NoSchoolContent extends StatelessWidget {
  const _NoSchoolContent();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.restaurant_outlined, color: colors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '학교를 등록하면 오늘 급식을 볼 수 있어요',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        TextButton(
          onPressed: () => context.push('/school-search'),
          child: const Text('등록'),
        ),
      ],
    );
  }
}

class _SchoolMealContent extends ConsumerWidget {
  const _SchoolMealContent({required this.school});

  final SchoolSelection school;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final meals = ref.watch(todayMealProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.restaurant_outlined, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${school.schoolName} 오늘 급식',
                style: textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/school-search'),
              child: const Text('변경'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        meals.when(
          loading: () => const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, _) => Row(
            children: [
              Text(
                '급식 정보를 불러오지 못했어요.',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => ref.invalidate(todayMealProvider),
                child: Text(
                  '다시 시도',
                  style: textTheme.bodySmall?.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
          data: (meals) => meals.isEmpty
              ? Text(
                  '오늘은 급식이 없어요.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final meal in meals)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          meals.length > 1
                              ? '${meal.mealName} · ${meal.menuItems.join(', ')}'
                              : meal.menuItems.join(', '),
                          style: textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

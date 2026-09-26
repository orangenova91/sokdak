import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'school.dart';
import 'school_providers.dart';

const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 주어진 날짜가 속한 주의 일요일(주 시작일)을 반환한다.
DateTime _sundayOf(DateTime d) => _dateOnly(d).subtract(Duration(days: d.weekday % 7));

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 일요일 시작 · 토요일 종료 주간 달력. 좌우로 스와이프해 주를 넘기고,
/// 날짜를 탭하면 그 날의 학사일정을 아래에 보여준다.
class WeekCalendarCard extends ConsumerStatefulWidget {
  const WeekCalendarCard({super.key});

  @override
  ConsumerState<WeekCalendarCard> createState() => _WeekCalendarCardState();
}

class _WeekCalendarCardState extends ConsumerState<WeekCalendarCard> {
  late DateTime _weekStart;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _weekStart = _sundayOf(today);
    _selectedDay = today;
  }

  void _shiftWeek(int deltaWeeks) {
    final offsetInWeek = _selectedDay.difference(_weekStart).inDays;
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * deltaWeeks));
      _selectedDay = _weekStart.add(Duration(days: offsetInWeek));
    });
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleEventsProvider);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final today = _dateOnly(DateTime.now());

    return schedule.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(
              '학사일정을 불러오지 못했어요.',
              style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => ref.invalidate(scheduleEventsProvider),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (events) {
        final eventsByDay = <DateTime, List<SchoolEvent>>{};
        for (final event in events) {
          eventsByDay.putIfAbsent(_dateOnly(event.date), () => []).add(event);
        }
        final selectedEvents = eventsByDay[_selectedDay] ?? const <SchoolEvent>[];
        final weekEnd = _weekStart.add(const Duration(days: 6));
        final rangeLabel = weekEnd.year == _weekStart.year
            ? '${_weekStart.month}월 ${_weekStart.day}일 ~ ${weekEnd.month}월 ${weekEnd.day}일'
            : '${_weekStart.year}.${_weekStart.month}.${_weekStart.day} ~ '
                  '${weekEnd.year}.${weekEnd.month}.${weekEnd.day}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _shiftWeek(-1),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: '이전 주',
                ),
                Text(rangeLabel, style: textTheme.titleSmall),
                IconButton(
                  onPressed: () => _shiftWeek(1),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: '다음 주',
                ),
              ],
            ),
            GestureDetector(
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -200) {
                  _shiftWeek(1);
                } else if (velocity > 200) {
                  _shiftWeek(-1);
                }
              },
              child: Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: _DayCell(
                        date: _weekStart.add(Duration(days: i)),
                        isToday: _isSameDay(_weekStart.add(Duration(days: i)), today),
                        isSelected: _isSameDay(
                          _weekStart.add(Duration(days: i)),
                          _selectedDay,
                        ),
                        hasEvent: eventsByDay.containsKey(
                          _weekStart.add(Duration(days: i)),
                        ),
                        onTap: () => setState(
                          () => _selectedDay = _weekStart.add(Duration(days: i)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (selectedEvents.isEmpty)
              Text(
                '이 날은 학사일정이 없어요.',
                style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final event in selectedEvents)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${event.name}', style: textTheme.bodyMedium),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.hasEvent,
    required this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool hasEvent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final weekdayIndex = date.weekday % 7; // 일=0 ... 토=6
    final labelColor = weekdayIndex == 0
        ? Colors.red
        : weekdayIndex == 6
        ? Colors.blue
        : colors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Text(
              _weekdayLabels[weekdayIndex],
              style: textTheme.bodySmall?.copyWith(color: labelColor),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? colors.primary : Colors.transparent,
                border: isToday && !isSelected
                    ? Border.all(color: colors.primary)
                    : null,
              ),
              child: Text(
                '${date.day}',
                style: textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? colors.onPrimary
                      : weekdayIndex == 0 && !isSelected
                      ? Colors.red
                      : weekdayIndex == 6 && !isSelected
                      ? Colors.blue
                      : null,
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 6,
              width: 6,
              child: hasEvent
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.primary,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'school.dart';
import 'school_providers.dart';
import 'month_schedule_sheet.dart';
import 'schedule_event_tile.dart';

const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 주어진 날짜가 속한 주의 일요일(주 시작일)을 반환한다.
DateTime _sundayOf(DateTime d) =>
    _dateOnly(d).subtract(Duration(days: d.weekday % 7));

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

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: schedule.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '학사일정을 불러오지 못했어요.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
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
              eventsByDay
                  .putIfAbsent(_dateOnly(event.date), () => [])
                  .add(event);
            }
            final selectedEvents =
                eventsByDay[_selectedDay] ?? const <SchoolEvent>[];
            final weekEnd = _weekStart.add(const Duration(days: 6));
            final rangeLabel = weekEnd.year == _weekStart.year
                ? '${_weekStart.month}월 ${_weekStart.day}일 ~ ${weekEnd.month}월 ${weekEnd.day}일'
                : '${_weekStart.year}.${_weekStart.month}.${_weekStart.day} ~ '
                      '${weekEnd.year}.${weekEnd.month}.${weekEnd.day}';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _shiftWeek(-1),
                      icon: const Icon(Icons.chevron_left),
                      tooltip: '이전 주',
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Text(
                        rangeLabel,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _shiftWeek(1),
                      icon: const Icon(Icons.chevron_right),
                      tooltip: '다음 주',
                      visualDensity: VisualDensity.compact,
                    ),
                    InkWell(
                      onTap: () => showMonthScheduleSheet(
                        context,
                        initialMonth: _weekStart,
                        initialSelectedDay: _selectedDay,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '한달',
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
                            isToday: _isSameDay(
                              _weekStart.add(Duration(days: i)),
                              today,
                            ),
                            isSelected: _isSameDay(
                              _weekStart.add(Duration(days: i)),
                              _selectedDay,
                            ),
                            hasEvent: eventsByDay.containsKey(
                              _weekStart.add(Duration(days: i)),
                            ),
                            onTap: () => setState(
                              () => _selectedDay = _weekStart.add(
                                Duration(days: i),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: selectedEvents.isEmpty
                      ? Text(
                          '이 날은 학사일정이 없어요.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < selectedEvents.length; i++) ...[
                              if (i > 0) const SizedBox(height: 8),
                              ScheduleEventTile(name: selectedEvents[i].name),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
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

  Color _weekdayColor(ColorScheme colors, int weekdayIndex) {
    if (weekdayIndex == 0) return colors.error;
    if (weekdayIndex == 6) return colors.tertiary;
    return colors.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final weekdayIndex = date.weekday % 7; // 일=0 ... 토=6
    final weekdayColor = _weekdayColor(colors, weekdayIndex);

    final Color? dayFill;
    if (isSelected) {
      dayFill = colors.primary;
    } else if (isToday) {
      dayFill = colors.primaryContainer;
    } else {
      dayFill = Colors.transparent;
    }

    final Color dayTextColor;
    if (isSelected) {
      dayTextColor = colors.onPrimary;
    } else if (isToday) {
      dayTextColor = colors.onPrimaryContainer;
    } else if (weekdayIndex == 0 || weekdayIndex == 6) {
      dayTextColor = weekdayColor;
    } else {
      dayTextColor = colors.onSurface;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Text(
              _weekdayLabels[weekdayIndex],
              style: textTheme.bodySmall?.copyWith(color: weekdayColor),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dayFill,
              ),
              child: Text(
                '${date.day}',
                style: textTheme.bodyMedium?.copyWith(
                  color: dayTextColor,
                  fontWeight: isToday || isSelected ? FontWeight.bold : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 4,
              width: 4,
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

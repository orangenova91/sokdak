import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'school.dart';
import 'school_providers.dart';
import 'schedule_event_tile.dart';

const _weekdayShort = ['일', '월', '화', '수', '목', '금', '토'];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _monthStart(DateTime d) => DateTime(d.year, d.month);

/// 월별 학사일정을 보여주는 바텀시트 (달력 + 선택일 목록).
Future<void> showMonthScheduleSheet(
  BuildContext context, {
  DateTime? initialMonth,
  DateTime? initialSelectedDay,
}) {
  final month = _monthStart(initialMonth ?? DateTime.now());
  final today = _dateOnly(DateTime.now());
  final selected = initialSelectedDay != null
      ? _dateOnly(initialSelectedDay)
      : (today.year == month.year && today.month == month.month
            ? today
            : month);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _MonthScheduleSheet(
      initialMonth: month,
      initialSelectedDay: selected,
    ),
  );
}

class _MonthScheduleSheet extends ConsumerStatefulWidget {
  const _MonthScheduleSheet({
    required this.initialMonth,
    required this.initialSelectedDay,
  });

  final DateTime initialMonth;
  final DateTime initialSelectedDay;

  @override
  ConsumerState<_MonthScheduleSheet> createState() =>
      _MonthScheduleSheetState();
}

class _MonthScheduleSheetState extends ConsumerState<_MonthScheduleSheet> {
  late DateTime _month;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth;
    _selectedDay = widget.initialSelectedDay;
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    final today = _dateOnly(DateTime.now());
    setState(() {
      _month = next;
      _selectedDay = today.year == next.year && today.month == next.month
          ? today
          : next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final schedule = ref.watch(scheduleEventsProvider);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final monthLabel = '${_month.year}년 ${_month.month}월';
    final today = _dateOnly(DateTime.now());

    return SizedBox(
      height: maxHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Text('학사일정', style: textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: '닫기',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _shiftMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: '이전 달',
                ),
                Expanded(
                  child: Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _shiftMonth(1),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: '다음 달',
                ),
              ],
            ),
          ),
          Expanded(
            child: schedule.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '학사일정을 불러오지 못했어요.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(scheduleEventsProvider),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (events) {
                final byDay = <DateTime, List<SchoolEvent>>{};
                for (final event in events) {
                  byDay
                      .putIfAbsent(_dateOnly(event.date), () => [])
                      .add(event);
                }
                final selectedEvents =
                    byDay[_selectedDay] ?? const <SchoolEvent>[];
                final weekday = _weekdayShort[_selectedDay.weekday % 7];
                final dayTitle =
                    '${_selectedDay.month}월 ${_selectedDay.day}일 ($weekday)';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _MonthGrid(
                        month: _month,
                        today: today,
                        selectedDay: _selectedDay,
                        eventsByDay: byDay,
                        onSelect: (day) =>
                            setState(() => _selectedDay = day),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(
                      height: 1,
                      color: colors.outlineVariant.withValues(alpha: 0.45),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        dayTitle,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: selectedEvents.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                8,
                                20,
                                24,
                              ),
                              child: Text(
                                '이 날은 학사일정이 없어요.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                28,
                              ),
                              itemCount: selectedEvents.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) =>
                                  ScheduleEventTile(
                                    name: selectedEvents[index].name,
                                  ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.selectedDay,
    required this.eventsByDay,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime today;
  final DateTime selectedDay;
  final Map<DateTime, List<SchoolEvent>> eventsByDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = first.weekday % 7; // 일=0

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    _weekdayShort[i],
                    style: textTheme.bodySmall?.copyWith(
                      color: i == 0
                          ? colors.error
                          : i == 6
                          ? colors.tertiary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < 6; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final cellIndex = row * 7 + col;
                        final dayNum = cellIndex - leadingEmpty + 1;
                        if (dayNum < 1 || dayNum > daysInMonth) {
                          return const SizedBox(height: 44);
                        }
                        final date = DateTime(month.year, month.month, dayNum);
                        final isToday = date == today;
                        final isSelected = date == selectedDay;
                        final hasEvent = eventsByDay.containsKey(date);

                        Color? fill;
                        if (isSelected) {
                          fill = colors.primary;
                        } else if (isToday) {
                          fill = colors.primaryContainer;
                        }

                        Color textColor;
                        if (isSelected) {
                          textColor = colors.onPrimary;
                        } else if (isToday) {
                          textColor = colors.onPrimaryContainer;
                        } else if (col == 0) {
                          textColor = colors.error;
                        } else if (col == 6) {
                          textColor = colors.tertiary;
                        } else {
                          textColor = colors.onSurface;
                        }

                        return InkWell(
                          onTap: () => onSelect(date),
                          borderRadius: BorderRadius.circular(22),
                          child: SizedBox(
                            height: 44,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: fill ?? Colors.transparent,
                                  ),
                                  child: Text(
                                    '$dayNum',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: textColor,
                                      fontWeight: isToday || isSelected
                                          ? FontWeight.bold
                                          : null,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 4,
                                  width: 4,
                                  child: hasEvent
                                      ? DecoratedBox(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? colors.onPrimary
                                                : colors.primary,
                                          ),
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

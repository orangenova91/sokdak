import 'package:flutter/material.dart';

/// 학사일정 한 줄 — 왼쪽 primary 바 + 행사명.
class ScheduleEventTile extends StatelessWidget {
  const ScheduleEventTile({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              child: Container(
                width: 4,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
                child: Text(name, style: textTheme.titleSmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

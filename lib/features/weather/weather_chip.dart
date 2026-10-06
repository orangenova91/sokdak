import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'weather.dart';
import 'weather_providers.dart';

/// 날짜 옆 compact 날씨 칩 (아이콘 + 기온).
class WeatherChip extends ConsumerWidget {
  const WeatherChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(currentWeatherProvider);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return weather.when(
      loading: () => SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.onSurfaceVariant,
        ),
      ),
      error: (_, _) => Icon(
        Icons.cloud_off_outlined,
        size: 22,
        color: colors.onSurfaceVariant,
      ),
      data: (data) {
        if (data == null) {
          return Icon(
            Icons.cloud_off_outlined,
            size: 22,
            color: colors.onSurfaceVariant,
          );
        }
        final visual = weatherVisual(data.skyLabel);
        return Tooltip(
          message: '${data.regionLabel} · ${data.skyLabel}',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.regionLabel,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Icon(visual.icon, size: 22, color: visual.color),
              const SizedBox(width: 4),
              Text(
                '${data.temperatureC}°',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

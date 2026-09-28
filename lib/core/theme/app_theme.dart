import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF4F7CAC);

  static ThemeData get light => _build(
    ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light),
  );

  /// 다크 표면을 남색 차콜로 올려 배경과 카드가 구분되게 한다.
  static ThemeData get dark => _build(_softDarkScheme());

  static ColorScheme _softDarkScheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return scheme.copyWith(
      surface: const Color(0xFF2A3850),
      surfaceDim: const Color(0xFF243044),
      surfaceBright: const Color(0xFF587492),
      surfaceContainerLowest: const Color(0xFF1B2838),
      surfaceContainerLow: const Color(0xFF33445C),
      surfaceContainer: const Color(0xFF3D5068),
      surfaceContainerHigh: const Color(0xFF445872),
      surfaceContainerHighest: const Color(0xFF4E6482),
      onSurface: const Color(0xFFE8EEF4),
      onSurfaceVariant: const Color(0xFFD7E0EA),
      outline: const Color(0xFF8A9BB0),
      outlineVariant: const Color(0xFF6A7E96),
    );
  }

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

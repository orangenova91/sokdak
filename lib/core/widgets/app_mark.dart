import 'package:flutter/material.dart';

/// 하단 탭 루트 화면 앱 바 왼쪽의 앱 마크. 누르는 동작은 없다.
class AppMark extends StatelessWidget {
  const AppMark({super.key});

  static const double leadingWidth = 52;
  static const double titleSpacing = 4;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/icon/app_mark.png',
            width: 32,
            height: 32,
            semanticLabel: '교무실 속닥속닥',
          ),
        ),
      ),
    );
  }
}

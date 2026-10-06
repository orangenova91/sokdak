import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/system/update_gate.dart';

class SokdakApp extends ConsumerWidget {
  const SokdakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UpdateGate(
      child: MaterialApp.router(
        title: '교무실 속닥속닥',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: ref.watch(appRouterProvider),
        builder: kIsWeb ? _phoneWidthFrame : null,
      ),
    );
  }
}

/// 웹에서 넓은 화면(노트북·프로젝터)으로 열어도 휴대폰 폭으로 가운데에 보이게 한다.
Widget _phoneWidthFrame(BuildContext context, Widget? child) {
  return ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: child,
      ),
    ),
  );
}

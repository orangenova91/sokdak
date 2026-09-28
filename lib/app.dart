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
      ),
    );
  }
}

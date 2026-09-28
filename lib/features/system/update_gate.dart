import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'app_update_provider.dart';
import 'system_screens.dart';
import 'update_required_screen.dart';

/// 최소 빌드보다 낮으면 [child] 대신 업데이트 화면만 보여 준다.
/// 서버에 닿지 않으면 앱을 그대로 연다.
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(appUpdateStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(appUpdateStatusProvider);
    return status.when(
      skipLoadingOnReload: true,
      loading: () => const _GateApp(home: SplashScreen()),
      error: (_, _) => widget.child,
      data: (status) => status.blocked
          ? _GateApp(home: UpdateRequiredScreen(storeUrl: status.storeUrl))
          : widget.child,
    );
  }
}

class _GateApp extends StatelessWidget {
  const _GateApp({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '교무실 속닥속닥',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: home,
    );
  }
}

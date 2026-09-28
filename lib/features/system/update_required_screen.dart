import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 최소 빌드보다 낮은 설치본. 다른 화면으로 넘어가지 않는다.
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key, required this.storeUrl});

  final String storeUrl;

  Future<void> _openStore() async {
    final uri = Uri.tryParse(storeUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.system_update_alt,
                      size: 48,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '새 버전이 나왔어요',
                      style: textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '이 버전은 더 이상 사용할 수 없어요. '
                      '스토어에서 업데이트한 뒤 다시 열어 주세요.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (storeUrl.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _openStore,
                          child: const Text('업데이트하기'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

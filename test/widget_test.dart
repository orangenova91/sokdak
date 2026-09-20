import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sokdak/app.dart';

void main() {
  testWidgets('Supabase 설정이 없으면 설정 안내 화면을 표시한다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SokdakApp()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Supabase 설정이 필요해요'), findsOneWidget);
  });
}

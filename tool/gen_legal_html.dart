// 앱 안의 약관 텍스트(lib/features/me/legal_texts.dart)를 스토어 제출용 정적 HTML로 내보낸다.
//
//   dart run tool/gen_legal_html.dart
//
// 결과: docs/legal/{privacy,terms,account-deletion}.html
// 개인정보 처리방침 URL, 계정 삭제 안내 URL은 스토어 등록에 필수이므로 이 파일들을 웹에 올려 사용한다.
import 'dart:io';

import 'package:sokdak/core/config/app_info.dart';
import 'package:sokdak/features/me/legal_texts.dart';

String escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('\n', '<br>');

String render(LegalDocument document) {
  final sections = document.sections
      .map((s) => '<h2>${escape(s.heading)}</h2>\n<p>${escape(s.body)}</p>')
      .join('\n');
  return '''<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escape(document.title)} - 교무실 속닥속닥</title>
<style>
  body { font-family: -apple-system, "Apple SD Gothic Neo", "Noto Sans KR", sans-serif;
         max-width: 720px; margin: 0 auto; padding: 24px 16px 64px; line-height: 1.7; color: #1c1b1f; }
  h1 { font-size: 1.5rem; }
  h2 { font-size: 1.05rem; margin-top: 2rem; }
  p { margin: .5rem 0; }
  .app { color: #3e6c9e; font-weight: 600; }
  @media (prefers-color-scheme: dark) { body { background: #121316; color: #e4e2e6; } .app { color: #9dc2eb; } }
</style>
</head>
<body>
<p class="app">교무실 속닥속닥</p>
<h1>${escape(document.title)}</h1>
$sections
</body>
</html>
''';
}

void main() {
  final out = Directory('docs/legal')..createSync(recursive: true);
  final files = {
    'privacy.html': withContactSection(privacyPolicy),
    'terms.html': withContactSection(termsOfService),
    'account-deletion.html': withContactSection(accountDeletionGuide),
  };
  files.forEach((name, document) {
    File('${out.path}/$name').writeAsStringSync(render(document));
    stdout.writeln('wrote docs/legal/$name');
  });
  if (AppInfo.contactEmail.isEmpty) {
    stdout.writeln(
      '\n⚠ AppInfo.contactEmail 이 비어 있어 "문의" 항목이 빠졌습니다. '
      '스토어 제출 전에 lib/core/config/app_info.dart 에 이메일을 넣고 다시 생성하세요.',
    );
  }
}

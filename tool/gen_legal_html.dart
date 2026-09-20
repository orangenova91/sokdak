// 스토어 제출용 정적 웹 페이지를 생성한다.
//
//   dart run tool/gen_legal_html.dart
//
// 결과: docs/index.html (지원 페이지), docs/legal/{privacy,terms,account-deletion,child-safety}.html
// 약관 본문은 앱 안의 텍스트(lib/features/me/legal_texts.dart)와 같은 원본을 쓴다.
// GitHub Pages(소스: main 브랜치의 /docs 폴더)로 게시하면 스토어 등록에 필요한 URL이 된다.
import 'dart:io';

import 'package:sokdak/core/config/app_info.dart';
import 'package:sokdak/features/me/legal_texts.dart';

const _style = '''
  body { font-family: -apple-system, "Apple SD Gothic Neo", "Noto Sans KR", sans-serif;
         max-width: 720px; margin: 0 auto; padding: 24px 16px 64px; line-height: 1.7; color: #1c1b1f; }
  h1 { font-size: 1.5rem; }
  h2 { font-size: 1.05rem; margin-top: 2rem; }
  p, li { margin: .5rem 0; }
  a { color: #3e6c9e; }
  .app { color: #3e6c9e; font-weight: 600; }
  @media (prefers-color-scheme: dark) {
    body { background: #121316; color: #e4e2e6; } .app { color: #9dc2eb; } a { color: #9dc2eb; }
  }''';

String escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('\n', '<br>');

String page({required String title, required String body}) =>
    '''<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escape(title)} - 교무실 속닥속닥</title>
<style>$_style
</style>
</head>
<body>
<p class="app">교무실 속닥속닥</p>
<h1>${escape(title)}</h1>
$body
</body>
</html>
''';

String renderLegal(LegalDocument document) {
  final sections = document.sections
      .map((s) => '<h2>${escape(s.heading)}</h2>\n<p>${escape(s.body)}</p>')
      .join('\n');
  return page(title: document.title, body: sections);
}

/// 스토어의 "지원 URL"로 쓰는 페이지: 서비스 소개, 연락처, 자주 묻는 질문, 약관 링크.
String renderSupport() {
  final email = AppInfo.contactEmail;
  final contact = email.isEmpty
      ? ''
      : '<h2>문의</h2>\n<p><a href="mailto:$email">$email</a><br>'
            '서비스 문의와 신고는 이메일로 보내 주세요. 신고 내용은 확인 후 조치합니다.</p>';
  const faq = '''
<h2>자주 묻는 질문</h2>
<p><strong>Q. 앱을 지웠다가 다시 설치했더니 계정이 없어졌어요.</strong><br>
이 서비스는 이메일이나 전화번호 없이 가입하는 익명 서비스여서 계정을 복구할 수 없어요. 새로 시작해 주세요.</p>
<p><strong>Q. 부적절한 글이나 댓글을 어떻게 신고하나요?</strong><br>
글 또는 댓글의 ⋯ 메뉴에서 [신고]를 누르고 사유를 선택해 주세요. 신고가 쌓이면 자동으로 숨겨져요.</p>
<p><strong>Q. 특정 사용자의 글이 보기 불편해요.</strong><br>
글 또는 댓글의 ⋯ 메뉴에서 [작성자 차단]을 누르면 더 이상 보이지 않아요. 내 정보 &gt; 차단한 사용자에서 해제할 수 있어요.</p>
<p><strong>Q. 계정과 작성한 글을 삭제하고 싶어요.</strong><br>
앱의 내 정보 &gt; 계정 삭제에서 직접 삭제할 수 있어요. 자세한 방법은 <a href="legal/account-deletion.html">계정 삭제 안내</a>를 참고해 주세요.</p>
<p><strong>Q. 어느 지역에서 쓸 수 있나요?</strong><br>
현재 울산 지역부터 글쓰기가 열려 있어요. 다른 지역은 준비 중이며, 가입은 미리 할 수 있어요.</p>''';
  const docs = '''
<h2>안내 문서</h2>
<ul>
<li><a href="legal/terms.html">이용약관</a></li>
<li><a href="legal/privacy.html">개인정보 처리방침</a></li>
<li><a href="legal/account-deletion.html">계정 삭제 안내</a></li>
<li><a href="legal/child-safety.html">아동 안전 표준</a></li>
</ul>''';
  return page(
    title: '지원',
    body:
        '<p>교무실 속닥속닥은 선생님들이 익명으로 고민을 나누고 노하우를 주고받는 커뮤니티 앱이에요.</p>\n$contact\n$faq\n$docs',
  );
}

void main() {
  final legal = Directory('docs/legal')..createSync(recursive: true);
  final files = <String, String>{
    'docs/index.html': renderSupport(),
    '${legal.path}/privacy.html': renderLegal(
      withContactSection(privacyPolicy),
    ),
    '${legal.path}/terms.html': renderLegal(withContactSection(termsOfService)),
    '${legal.path}/account-deletion.html': renderLegal(
      withContactSection(accountDeletionGuide),
    ),
    '${legal.path}/child-safety.html': renderLegal(childSafetyStandards),
  };
  files.forEach((path, html) {
    File(path).writeAsStringSync(html);
    stdout.writeln('wrote $path');
  });
  if (AppInfo.contactEmail.isEmpty) {
    stdout.writeln(
      '\n⚠ AppInfo.contactEmail 이 비어 있어 문의 정보가 빠졌습니다. '
      'lib/core/config/app_info.dart 에 이메일을 넣고 다시 생성하세요.',
    );
  }
}

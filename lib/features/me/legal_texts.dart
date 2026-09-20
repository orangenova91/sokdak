import '../../core/config/app_info.dart';

// 이용약관·개인정보 처리방침 본문.
// 출시 전에 법률 전문가의 검토를 받고, 운영 주체 정보(상호, 연락처)를 채워야 한다.

class LegalSection {
  const LegalSection(this.heading, this.body);

  final String heading;
  final String body;
}

class LegalDocument {
  const LegalDocument({required this.title, required this.sections});

  final String title;
  final List<LegalSection> sections;
}

const termsOfService = LegalDocument(
  title: '이용약관',
  sections: [
    LegalSection('1. 서비스 소개', '교무실 속닥속닥은 교사들이 익명으로 이야기와 노하우를 나누는 커뮤니티입니다.'),
    LegalSection(
      '2. 익명성',
      '가입에는 이메일이나 전화번호가 필요하지 않습니다. 앱을 삭제하거나 기기를 바꾸면 '
          '계정을 복구할 수 없습니다. 이용자는 언제든지 내 정보 화면에서 계정과 작성한 내용을 삭제할 수 있습니다.',
    ),
    LegalSection(
      '3. 금지 행위',
      '다음 행위는 금지되며, 신고가 누적되면 글과 댓글이 자동으로 숨겨지고 이용이 제한될 수 있습니다.\n'
          '• 학생, 학부모, 동료 교사 등 특정인의 실명·연락처·주민등록번호 등 개인정보를 공개하는 행위\n'
          '• 특정인을 알아볼 수 있는 방식의 비방, 욕설, 명예훼손\n'
          '• 광고, 스팸, 도배\n'
          '• 불법 정보 게시 및 타인의 권리 침해\n'
          '• 교사가 아닌 사람이 교사인 것처럼 가장하는 행위',
    ),
    LegalSection(
      '4. 신고와 차단',
      '부적절한 글과 댓글은 신고할 수 있고, 불편한 작성자는 차단할 수 있습니다. '
          '신고가 일정 수 이상 쌓이면 해당 내용은 다른 이용자에게 보이지 않게 됩니다. '
          '운영자는 신고 내용을 검토하여 삭제, 이용 제한 등의 조치를 할 수 있습니다.',
    ),
    LegalSection(
      '5. 게시물의 책임',
      '게시물에 대한 책임은 작성자에게 있습니다. 게시물이 타인의 권리를 침해하는 경우 '
          '운영자는 사전 통보 없이 이를 숨기거나 삭제할 수 있습니다.',
    ),
    LegalSection(
      '6. 서비스 변경 및 중단',
      '운영자는 서비스 개선을 위해 기능을 변경하거나 일시적으로 중단할 수 있으며, '
          '중요한 변경은 앱 안에서 안내합니다.',
    ),
  ],
);

const privacyPolicy = LegalDocument(
  title: '개인정보 처리방침',
  sections: [
    LegalSection(
      '1. 수집하는 정보',
      '• 익명 계정 식별자(자동 생성)\n'
          '• 닉네임, 지역, 학교급 (이용자가 직접 입력)\n'
          '• 이용자가 작성한 글, 댓글, 공감, 신고, 차단 내역\n'
          '이메일, 전화번호, 실명은 수집하지 않습니다.',
    ),
    LegalSection(
      '2. 이용 목적',
      '커뮤니티 서비스 제공, 지역별 게시판 구성, 부정 이용 방지와 신고 처리를 위해 사용합니다.',
    ),
    LegalSection(
      '3. 익명성 보호',
      '다른 이용자에게는 닉네임과 날짜(오늘/어제 등)만 표시되며, 정확한 작성 시각은 표시되지 않습니다.',
    ),
    LegalSection(
      '4. 보관과 삭제',
      '이용자가 내 정보 화면에서 계정을 삭제하면 계정 정보와 작성한 글, 댓글, 공감, 신고, 차단 내역이 '
          '즉시 삭제됩니다. 계정 삭제 없이 앱만 지운 경우에는 작성한 내용이 서버에 남을 수 있으므로, '
          '탈퇴를 원하시면 앱 안에서 계정을 삭제해 주세요.',
    ),
    LegalSection(
      '5. 교사 인증 (도입 예정)',
      '교사 인증 기능이 도입되면 이메일 원문은 저장하지 않고, 중복 가입을 막기 위한 '
          '변환값(해시)만 저장하며 계정과 연결하지 않습니다. 도입 시 본 방침을 갱신해 안내합니다.',
    ),
    LegalSection('6. 처리 위탁', '서비스 운영을 위해 Supabase(데이터베이스·인증 인프라)를 이용합니다.'),
  ],
);

const accountDeletionGuide = LegalDocument(
  title: '계정 삭제 안내',
  sections: [
    LegalSection(
      '앱에서 삭제하는 방법',
      '1. 앱 하단의 [내 정보] 탭을 엽니다.\n'
          '2. [계정 삭제]를 누릅니다.\n'
          '3. 확인 창에서 [삭제]를 누릅니다.',
    ),
    LegalSection(
      '삭제되는 정보',
      '계정, 닉네임, 지역, 학교급, 작성한 글과 댓글, 공감, 신고, 차단 내역이 서버에서 즉시 삭제되며 '
          '복구할 수 없습니다.',
    ),
    LegalSection(
      '알아 두세요',
      '이 서비스는 이메일이나 전화번호 없이 가입하는 익명 서비스여서, 앱 밖에서 계정을 특정해 삭제를 '
          '요청할 방법이 없습니다. 삭제는 앱 안에서 직접 진행해 주세요. 앱을 삭제하기만 하면 계정과 '
          '작성한 내용은 서버에 남습니다.',
    ),
  ],
);

/// 문의 이메일이 설정되어 있으면 문서 끝에 "문의" 항목을 붙인다.
LegalDocument withContactSection(LegalDocument document) {
  if (AppInfo.contactEmail.isEmpty) return document;
  return LegalDocument(
    title: document.title,
    sections: [
      ...document.sections,
      const LegalSection('문의', '서비스 문의와 신고는 ${AppInfo.contactEmail} 로 보내 주세요.'),
    ],
  );
}

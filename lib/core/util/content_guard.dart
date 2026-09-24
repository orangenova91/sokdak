/// 글/댓글 작성 전 개인정보와 욕설·비하 표현이 섞였는지 확인한다.
///
/// App Store 1.2(사용자 생성 콘텐츠) 요건 중 "부적절한 콘텐츠 필터링"을 위한 1차 방어선이다.
/// 여기서 걸러지지 않은 내용은 신고 → 3건 누적 자동 숨김, 그리고 운영자의 수동 검토·삭제·계정
/// 정지로 이어진다 (자세한 내용은 docs/store-submission.md 참고).
class ContentGuard {
  static final _phone = RegExp(r'01[016789][-.\s]?\d{3,4}[-.\s]?\d{4}');
  static final _residentNumber = RegExp(r'\d{6}[-\s]?[1-4]\d{6}');

  /// 공백이나 문장부호로 글자를 띄워 쓰는 흔한 우회(예: "시 발", "개-새끼")를 줄이기 위해
  /// 공백·문장부호만 제거한다. 한글 음절과 자모(ㅅㅂ 같은 표현)는 그대로 남겨 둔다.
  static final _separators = RegExp(
    r'''[\s.\-_*~!@#$%^&()+=\[\]{}|\\/:;"'<>,?`]''',
  );

  static String _normalize(String text) {
    return text.toLowerCase().replaceAll(_separators, '');
  }

  /// 대표적인 욕설·비하 표현. 완전한 금칙어 사전은 아니며, 신고·검토 체계와 함께 동작한다.
  static const _profanity = [
    '씨발',
    '시발',
    '씨팔',
    '씨뱔',
    'ㅅㅂ',
    'ㅆㅂ',
    '개새끼',
    '개새키',
    '병신',
    'ㅂㅅ',
    '지랄',
    '좆',
    '미친놈',
    '미친년',
    '닥쳐',
    '꺼져',
    '죽여버',
    'fuck',
    'motherfucker',
    'bitch',
    'asshole',
    'nigger',
  ];

  /// 문제가 있으면 사용자에게 보여 줄 안내 문구, 없으면 null.
  static String? check(String text) {
    if (_phone.hasMatch(text) || _residentNumber.hasMatch(text)) {
      return '전화번호나 주민등록번호처럼 보이는 내용이 있어요. 개인정보는 지워 주세요.';
    }
    final normalized = _normalize(text);
    for (final word in _profanity) {
      if (normalized.contains(word)) {
        return '욕설이나 비하 표현이 있는 것 같아요. 다른 선생님도 함께 보는 공간이니 표현을 다듬어 주세요.';
      }
    }
    return null;
  }
}

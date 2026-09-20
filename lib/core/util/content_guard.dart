/// 글/댓글 작성 전 개인정보(전화번호, 주민등록번호)가 섞였는지 확인한다.
class ContentGuard {
  static final _phone = RegExp(r'01[016789][-.\s]?\d{3,4}[-.\s]?\d{4}');
  static final _residentNumber = RegExp(r'\d{6}[-\s]?[1-4]\d{6}');

  /// 문제가 있으면 사용자에게 보여 줄 안내 문구, 없으면 null.
  static String? check(String text) {
    if (_phone.hasMatch(text) || _residentNumber.hasMatch(text)) {
      return '전화번호나 주민등록번호처럼 보이는 내용이 있어요. 개인정보는 지워 주세요.';
    }
    return null;
  }
}

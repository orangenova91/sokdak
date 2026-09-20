/// 익명성을 위해 정확한 작성 시각 대신 날짜 단위로만 표시한다.
/// (소규모 지역에서 작성 시각으로 글쓴이가 추정되는 것을 줄이기 위함)
String formatFuzzyDate(DateTime createdAt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final created = createdAt.toLocal();

  // 서머타임 등으로 하루 길이가 달라져도 날짜 차이가 틀어지지 않도록 UTC 자정으로 비교한다.
  final today = DateTime.utc(current.year, current.month, current.day);
  final createdDay = DateTime.utc(created.year, created.month, created.day);
  final days = today.difference(createdDay).inDays;

  if (days <= 0) return '오늘';
  if (days == 1) return '어제';
  if (days < 7) return '$days일 전';
  return '${created.month}월 ${created.day}일';
}

/// 시도교육청별 가입 집계. [signupCount]는 인원이 적어 가려진 경우 null이다.
class RegionSignupStat {
  const RegionSignupStat({
    required this.regionCode,
    required this.regionName,
    required this.sortOrder,
    required this.teacherCount,
    required this.statsYear,
    required this.signupCount,
    required this.suppressed,
  });

  factory RegionSignupStat.fromJson(Map<String, dynamic> json) {
    final suppressed = json['suppressed'] as bool;
    return RegionSignupStat(
      regionCode: json['region_code'] as String,
      regionName: json['region_name'] as String,
      sortOrder: json['sort_order'] as int,
      teacherCount: json['teacher_count'] as int,
      statsYear: json['stats_year'] as int,
      signupCount: suppressed ? null : json['signup_count'] as int?,
      suppressed: suppressed,
    );
  }

  final String regionCode;
  final String regionName;
  final int sortOrder;
  final int teacherCount;
  final int statsYear;
  final int? signupCount;
  final bool suppressed;

  double? get rate {
    final count = signupCount;
    if (suppressed || count == null || teacherCount == 0) return null;
    return count / teacherCount;
  }

  /// 내 정보 목록에 쓰는 한 줄.
  String get summaryLabel {
    if (rate == null) return '$regionName · 집계 중';
    return '$regionName · ${formatGrouped(signupCount!)}명 / ${formatGrouped(teacherCount)}명';
  }
}

/// 내 교육청을 맨 위에 두고, 공개된 지역은 가입 비율이 높은 순으로 둔다.
/// 가려진 지역은 원래 정렬 순서를 유지한 채 뒤에 둔다.
List<RegionSignupStat> arrangeRegionSignupStats(
  List<RegionSignupStat> stats, {
  required String? myRegionCode,
}) {
  final mine = stats.where((stat) => stat.regionCode == myRegionCode);
  final rest = stats.where((stat) => stat.regionCode != myRegionCode);
  final visible = rest.where((stat) => stat.rate != null).toList()
    ..sort((a, b) {
      final byRate = b.rate!.compareTo(a.rate!);
      if (byRate != 0) return byRate;
      return a.sortOrder.compareTo(b.sortOrder);
    });
  final hidden = rest.where((stat) => stat.rate == null).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  return [...mine, ...visible, ...hidden];
}

String formatGrouped(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}

String formatSignupRate(double rate) {
  final percent = rate * 100;
  if (percent == 0) return '0%';
  if (percent >= 10) return '${percent.toStringAsFixed(0)}%';
  if (percent >= 1) return '${percent.toStringAsFixed(1)}%';
  return '${percent.toStringAsFixed(2)}%';
}

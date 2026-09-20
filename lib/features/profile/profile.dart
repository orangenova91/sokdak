enum SchoolLevel {
  elementary('elementary', '초등'),
  middle('middle', '중등'),
  high('high', '고등'),
  special('special', '특수'),
  other('other', '기타');

  const SchoolLevel(this.value, this.label);

  /// DB `profiles.school_level` 에 저장되는 값
  final String value;
  final String label;

  static SchoolLevel fromValue(String value) {
    return SchoolLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => SchoolLevel.other,
    );
  }
}

class Region {
  const Region({
    required this.code,
    required this.name,
    required this.isActive,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      code: json['code'] as String,
      name: json['name'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  final String code;
  final String name;

  /// 글쓰기가 열린 지역인지 여부
  final bool isActive;
}

class Profile {
  const Profile({
    required this.id,
    required this.nickname,
    required this.regionCode,
    required this.schoolLevel,
    required this.isVerified,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      regionCode: json['region_code'] as String,
      schoolLevel: SchoolLevel.fromValue(json['school_level'] as String),
      isVerified: json['is_verified'] as bool,
    );
  }

  final String id;
  final String nickname;
  final String regionCode;
  final SchoolLevel schoolLevel;
  final bool isVerified;
}

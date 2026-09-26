/// 이용자가 등록한 소속 학교. `school_selections` 테이블 1행에 대응한다.
class SchoolSelection {
  const SchoolSelection({
    required this.officeCode,
    required this.schoolCode,
    required this.schoolName,
  });

  factory SchoolSelection.fromJson(Map<String, dynamic> json) {
    return SchoolSelection(
      officeCode: json['office_code'] as String,
      schoolCode: json['school_code'] as String,
      schoolName: json['school_name'] as String,
    );
  }

  final String officeCode;
  final String schoolCode;
  final String schoolName;
}

/// 나이스 학교기본정보 API 검색 결과 한 건.
class NeisSchool {
  const NeisSchool({
    required this.officeCode,
    required this.schoolCode,
    required this.name,
    required this.officeName,
    required this.address,
  });

  final String officeCode;
  final String schoolCode;
  final String name;
  final String officeName;
  final String address;
}

/// 나이스 급식식단정보 API의 한 끼(조식/중식/석식) 정보.
class MealInfo {
  const MealInfo({required this.mealName, required this.menuItems});

  final String mealName;
  final List<String> menuItems;
}

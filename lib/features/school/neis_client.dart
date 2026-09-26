import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'school.dart';

/// 나이스 Open API가 명시적 오류(RESULT.CODE가 ERROR로 시작)를 돌려줬을 때 던진다.
/// 데이터가 없는 경우(INFO-200)는 예외가 아니라 빈 목록으로 처리한다.
class NeisApiException implements Exception {
  const NeisApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NeisClient {
  NeisClient(this._httpClient, {required this.apiKey});

  final http.Client _httpClient;
  final String apiKey;

  static const _base = 'https://open.neis.go.kr/hub';
  static const _timeout = Duration(seconds: 10);

  Future<List<NeisSchool>> searchSchools(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final body = await _get('schoolInfo', {'SCHUL_NM': trimmed, 'pSize': '30'});
    final rows = extractNeisRows(body, 'schoolInfo');
    return rows
        .map(
          (row) => NeisSchool(
            officeCode: row['ATPT_OFCDC_SC_CODE'] as String,
            schoolCode: row['SD_SCHUL_CODE'] as String,
            name: row['SCHUL_NM'] as String,
            officeName: (row['ATPT_OFCDC_SC_NM'] as String?) ?? '',
            address: (row['ORG_RDNMA'] as String?) ?? '',
          ),
        )
        .toList();
  }

  Future<List<MealInfo>> fetchMeals({
    required String officeCode,
    required String schoolCode,
    required DateTime date,
  }) async {
    final body = await _get('mealServiceDietInfo', {
      'ATPT_OFCDC_SC_CODE': officeCode,
      'SD_SCHUL_CODE': schoolCode,
      'MLSV_YMD': DateFormat('yyyyMMdd').format(date),
    });
    final rows = extractNeisRows(body, 'mealServiceDietInfo');
    return rows
        .map(
          (row) => MealInfo(
            mealName: (row['MMEAL_SC_NM'] as String?) ?? '급식',
            menuItems: parseMenuItems((row['DDISH_NM'] as String?) ?? ''),
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> _get(
    String endpoint,
    Map<String, String> params,
  ) async {
    final uri = Uri.parse('$_base/$endpoint').replace(
      queryParameters: {'KEY': apiKey, 'Type': 'json', 'pIndex': '1', ...params},
    );
    final http.Response response;
    try {
      response = await _httpClient.get(uri).timeout(_timeout);
    } catch (_) {
      throw const NeisApiException('나이스 서버에 연결하지 못했어요.');
    }
    if (response.statusCode != 200) {
      throw const NeisApiException('나이스 서버에 연결하지 못했어요.');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}

/// 나이스 응답에서 실제 데이터 행(row)만 뽑아낸다.
/// - 정상: `{"<key>": [{"head": [...]}, {"row": [...]}]}`
/// - 데이터 없음(INFO-200): `{"RESULT": {"CODE": "INFO-200", ...}}` → 빈 목록
/// - 오류(ERROR-*): 위와 같은 모양 → [NeisApiException]
List<Map<String, dynamic>> extractNeisRows(
  Map<String, dynamic> body,
  String key,
) {
  final section = body[key];
  if (section is List) {
    for (final item in section) {
      if (item is Map<String, dynamic> && item['row'] is List) {
        return (item['row'] as List).cast<Map<String, dynamic>>();
      }
    }
  }

  final result = body['RESULT'];
  if (result is Map<String, dynamic>) {
    final code = result['CODE'] as String? ?? '';
    if (code.startsWith('ERROR')) {
      throw NeisApiException(
        result['MESSAGE'] as String? ?? '나이스에서 정보를 가져오지 못했어요.',
      );
    }
  }
  return const [];
}

/// "쌀밥/잡곡밥<br/>어묵국<br/>돈육불고기 (5.6.10.13)" 형태의 원문을 메뉴 목록으로 바꾼다.
/// 알레르기 유발 식재료 번호(괄호 안 숫자)는 대시보드에서는 필요 없어 제거한다.
List<String> parseMenuItems(String raw) {
  return raw
      .split('<br/>')
      .map((item) => item.replaceAll(RegExp(r'\s*\([\d.\s]+\)\s*$'), '').trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

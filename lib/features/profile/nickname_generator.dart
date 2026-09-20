import 'dart:math';

/// 닉네임 추천용 생성기. 결과는 항상 12자 이하 ("형용사 명사").
class NicknameGenerator {
  static const _adjectives = [
    '포근한',
    '졸린',
    '느긋한',
    '씩씩한',
    '따뜻한',
    '차분한',
    '든든한',
    '수줍은',
    '반짝이는',
    '조용한',
    '부지런한',
    '유쾌한',
    '다정한',
    '엉뚱한',
  ];

  static const _nouns = [
    '분필',
    '출석부',
    '칠판',
    '지우개',
    '시간표',
    '교무실',
    '커피',
    '메모지',
    '보온병',
    '실내화',
    '연필',
    '종소리',
    '복도',
    '창가',
  ];

  static String generate([Random? random]) {
    final rng = random ?? Random();
    final adjective = _adjectives[rng.nextInt(_adjectives.length)];
    final noun = _nouns[rng.nextInt(_nouns.length)];
    return '$adjective $noun';
  }
}

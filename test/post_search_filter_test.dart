import 'package:flutter_test/flutter_test.dart';
import 'package:sokdak/features/board/board_repository.dart';

void main() {
  test('제목과 본문을 함께 찾고 와일드카드는 글자로 다룬다', () {
    expect(postTextSearchFilter('학급'), 'title.ilike."%학급%",body.ilike."%학급%"');
    expect(
      postTextSearchFilter('100%'),
      r'title.ilike."%100\%%",body.ilike."%100\%%"',
    );
    expect(
      postTextSearchFilter('a,b'),
      'title.ilike."%a,b%",body.ilike."%a,b%"',
    );
  });
}

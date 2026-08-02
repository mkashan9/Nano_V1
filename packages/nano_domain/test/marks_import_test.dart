import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses marks csv by stable student ids', () {
    final rows = MarksImportCsv.parse('''
student_user_id,display_name,status,obtained_marks,remarks
aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa,Ali Khan,scored,18,Good
bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb,Sara,absent,,
''');
    expect(rows, hasLength(2));
    expect(rows.first['student_user_id'], TenancyFixtures.aliAlphaId);
    expect(rows.first['status'], 'scored');
    expect(rows.first['obtained_marks'], '18');
    expect(rows[1]['status'], 'absent');
  });
}

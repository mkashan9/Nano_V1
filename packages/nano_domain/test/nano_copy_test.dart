import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('Urdu locale is RTL and English is LTR', () {
    expect(NanoAppLocale.ur.isRtl, isTrue);
    expect(NanoAppLocale.en.isRtl, isFalse);
    expect(NanoAppLocale.fromTag('ur-PK'), NanoAppLocale.ur);
  });

  test('foundation copy switches language', () {
    final en = NanoCopy(NanoAppLocale.en);
    final ur = NanoCopy(NanoAppLocale.ur);
    expect(en.home, 'Home');
    expect(ur.home, 'گھر');
    expect(en.greeting('Ali'), 'Hi Ali');
    expect(ur.greeting('Ali'), 'سلام Ali');
    expect(en.studentNavLabel('profile', junior: true), 'Me');
    expect(ur.studentNavLabel('profile', junior: true), 'میں');
  });
}

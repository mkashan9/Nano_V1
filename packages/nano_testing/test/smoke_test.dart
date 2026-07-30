import 'package:flutter_test/flutter_test.dart';
import 'package:nano_testing/nano_testing.dart';

void main() {
  test('testing package loads', () {
    expect(const NanoTesting(), isNotNull);
  });
}

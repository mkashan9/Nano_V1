import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';

void main() {
  test('light theme builds', () {
    final theme = NanoTheme.light();
    expect(theme.colorScheme.primary, isNotNull);
  });
}

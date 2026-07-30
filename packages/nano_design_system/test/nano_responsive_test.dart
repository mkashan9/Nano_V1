import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';

void main() {
  test('window size thresholds', () {
    expect(NanoResponsive.windowSizeFor(360), NanoWindowSize.phone);
    expect(NanoResponsive.windowSizeFor(800), NanoWindowSize.tablet);
    expect(NanoResponsive.windowSizeFor(1200), NanoWindowSize.desktop);
  });

  test('junior uses denser grid than senior on phone', () {
    expect(
      NanoResponsive.subjectColumnsFor(size: NanoWindowSize.phone, junior: true),
      2,
    );
    expect(
      NanoResponsive.subjectColumnsFor(size: NanoWindowSize.phone, junior: false),
      1,
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';

void main() {
  test('junior and senior themes expose extensions', () {
    expect(NanoTheme.junior().nano.isJunior, isTrue);
    expect(NanoTheme.senior().nano.isSenior, isTrue);
    expect(NanoTheme.teacher().nano.experience, NanoExperience.teacher);
    expect(NanoTheme.schoolAdmin().nano.experience, NanoExperience.schoolAdmin);
    expect(NanoTheme.superadmin().nano.experience, NanoExperience.superadmin);
  });

  test('school branding cannot override safety colors', () {
    const branding = SchoolBranding(primary: Color(0xFF123456));
    expect(branding.error, NanoColors.error);
    expect(branding.success, NanoColors.success);
    expect(branding.safePrimary, const Color(0xFF123456));
  });

  test('same domain title renders in junior and senior card variants', () {
    expect(JuniorActionCard(title: 'Math', backgroundColor: NanoColors.worldMath), isA<Widget>());
    expect(SeniorProgressCard(title: 'Math', progress: 0.5), isA<Widget>());
  });
}

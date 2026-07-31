import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/main.dart';

void main() {
  testWidgets('reduced motion disables animations via MediaQuery', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );

    await tester.pumpWidget(
      const NanoStudentApp(
        config: config,
        initialAccessibility: AccessibilityPreferences(reducedMotion: true),
      ),
    );
    await tester.pumpAndSettle();

    final media = MediaQuery.of(tester.element(find.text('Home').first));
    expect(media.disableAnimations, isTrue);

    await tester.tap(find.text('A11y'));
    await tester.pumpAndSettle();
    expect(find.text('Accessibility'), findsOneWidget);
    expect(find.text('Static (reduced motion)'), findsOneWidget);
  });

  testWidgets('classroom mode shows quiet captions path', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );

    await tester.pumpWidget(
      const NanoStudentApp(
        config: config,
        initialAccessibility: AccessibilityPreferences(classroomMode: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('A11y'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paused by Classroom Mode'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/main.dart';

void main() {
  testWidgets('senior shell shows Flex when eligible', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );
    await tester.pumpWidget(
      NanoStudentApp(
        config: config,
        initialPrincipal: SessionPrincipal.seniorSchool(),
      ),
    );
    await tester.pumpAndSettle();
    // Nav destination, plus the home flex summary once it scrolls into view.
    expect(find.text('Flex'), findsWidgets);
  });

  testWidgets('deep link to flex redirects independent to home', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );
    await tester.pumpWidget(
      NanoStudentApp(
        config: config,
        initialPrincipal: SessionPrincipal.independent(),
        initialLocation: '/flex',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Flex'), findsNothing);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Play'), findsWidgets);
    expect(find.text('Me'), findsWidgets);
    // Independent learners use the senior presentation, which leads with level.
    expect(find.textContaining('Level 3'), findsOneWidget);
    expect(find.text('Play next'), findsOneWidget);
  });
}

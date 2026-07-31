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
    expect(find.text('Flex'), findsOneWidget);
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
    expect(find.text('Learning'), findsWidgets);
    expect(find.text("Today's Mission"), findsOneWidget);
  });
}

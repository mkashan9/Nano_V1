import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/main.dart';

void main() {
  testWidgets('student home shows Nano and junior subjects', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );
    await tester.pumpWidget(const NanoStudentApp(config: config));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nano'), findsWidgets);
    expect(find.text('Math'), findsOneWidget);
    expect(find.text('Responsive preview'), findsOneWidget);
  });
}

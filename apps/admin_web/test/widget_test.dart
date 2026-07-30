import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:admin_web/main.dart';

void main() {
  testWidgets('admin foundation loads', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {},
    );
    await tester.pumpWidget(const NanoAdminApp(config: config));
    expect(find.textContaining('Admin'), findsWidgets);
  });
}

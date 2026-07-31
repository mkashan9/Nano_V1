import 'package:nano_data/nano_data.dart';
import 'package:test/test.dart';

void main() {
  test('AppHealthSnapshot holds schema version', () {
    const snap = AppHealthSnapshot(
      environment: 'development',
      schemaVersion: 'SEC-01',
      notes: 'ok',
    );
    expect(snap.schemaVersion, 'SEC-01');
  });
}

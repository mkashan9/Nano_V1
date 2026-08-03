import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('lock screen preview hides marks detail', () {
    expect(
      PushDeliveryPolicy.lockScreenPreview(
        category: 'marks',
        title: 'Marks published',
        body: 'Math 92%',
      ),
      'You have a new Nano update',
    );
    expect(
      PushDeliveryPolicy.lockScreenPreview(
        category: 'learning',
        title: 'Topic ready',
        body: 'Forces is waiting.',
      ),
      'Forces is waiting.',
    );
  });

  test('looksLikeToken rejects short or invalid markers', () {
    expect(PushDeliveryPolicy.looksLikeToken('fake-device-token-01'), isTrue);
    expect(PushDeliveryPolicy.looksLikeToken('short'), isFalse);
    expect(PushDeliveryPolicy.looksLikeToken('token-invalid-x'), isFalse);
  });
}

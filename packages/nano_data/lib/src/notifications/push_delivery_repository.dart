import 'package:nano_domain/nano_domain.dart';

import 'student_notification_inbox_repository.dart';

/// NOT-01 device token + fake push delivery into the student inbox.
abstract class PushDeliveryRepository {
  Future<DeviceToken> registerToken({
    required String userId,
    required String token,
    String platform = 'fake',
  });

  Future<void> invalidateToken(String token);

  Future<List<DeviceToken>> listTokens({required String userId});

  Future<int> cleanupInvalidTokens();

  Future<PushDeliveryResult> deliver(PushEvent event);
}

class FakePushDeliveryRepository implements PushDeliveryRepository {
  FakePushDeliveryRepository({
    required this.inbox,
    List<DeviceToken>? tokens,
    this.alwaysFail = false,
  }) : _tokens = List.of(tokens ?? const []);

  final StudentNotificationInboxRepository inbox;
  final List<DeviceToken> _tokens;
  bool alwaysFail;

  @override
  Future<DeviceToken> registerToken({
    required String userId,
    required String token,
    String platform = 'fake',
  }) async {
    if (alwaysFail) throw StateError('Token register failed');
    final normalized = token.trim();
    if (!PushDeliveryPolicy.looksLikeToken(normalized)) {
      throw ArgumentError('Invalid device token');
    }
    final now = DateTime.now().toUtc();
    final index = _tokens.indexWhere((item) => item.token == normalized);
    final next = DeviceToken(
      token: normalized,
      userId: userId.trim(),
      platform: platform,
      status: DeviceTokenStatus.active,
      updatedAt: now,
    );
    if (index >= 0) {
      _tokens[index] = next;
    } else {
      _tokens.add(next);
    }
    return next;
  }

  @override
  Future<void> invalidateToken(String token) async {
    if (alwaysFail) throw StateError('Token invalidate failed');
    final normalized = token.trim();
    final index = _tokens.indexWhere((item) => item.token == normalized);
    if (index < 0) return;
    _tokens[index] = _tokens[index].copyWith(
      status: DeviceTokenStatus.invalid,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<List<DeviceToken>> listTokens({required String userId}) async {
    if (alwaysFail) throw StateError('Token list failed');
    return [
      for (final token in _tokens)
        if (token.userId == userId) token,
    ];
  }

  @override
  Future<int> cleanupInvalidTokens() async {
    if (alwaysFail) throw StateError('Token cleanup failed');
    final before = _tokens.length;
    _tokens.removeWhere((token) => !token.isActive);
    return before - _tokens.length;
  }

  @override
  Future<PushDeliveryResult> deliver(PushEvent event) async {
    if (alwaysFail) throw StateError('Push deliver failed');
    final preview = PushDeliveryPolicy.lockScreenPreview(
      category: event.category,
      title: event.title,
      body: event.body,
    );

    final active = _tokens.any(
      (token) =>
          token.isActive && token.userId == event.recipientUserId,
    );
    if (!active) {
      return PushDeliveryResult(
        outcome: PushDeliveryOutcome.noActiveToken,
        lockScreenPreview: preview,
      );
    }

    final before = await inbox.listInbox();
    final existing = before.where(
      (item) => item.sourceEventId == event.eventId,
    );
    if (existing.isNotEmpty) {
      return PushDeliveryResult(
        outcome: PushDeliveryOutcome.duplicated,
        inboxItemId: existing.first.id,
        lockScreenPreview: preview,
      );
    }

    final created = await inbox.deliverFromPush(
      sourceEventId: event.eventId,
      category: event.category,
      title: event.title,
      body: event.body,
      deepLinkPath: event.deepLinkPath,
    );
    return PushDeliveryResult(
      outcome: PushDeliveryOutcome.delivered,
      inboxItemId: created.id,
      lockScreenPreview: preview,
    );
  }
}

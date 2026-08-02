import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// SAFE-03 policy checks exposed to clients for preview / status.
abstract class SafetyPolicyRepository {
  Future<SafetyTextCheck> checkText(String text);

  Future<SafetyRateStatus> rateStatus(SafetyActionKey action);
}

class FakeSafetyPolicyRepository implements SafetyPolicyRepository {
  FakeSafetyPolicyRepository({
    this.bannedSubstring = 'nano_banned_phrase_test',
    this.blockUnknownLinks = true,
  });

  final String bannedSubstring;
  final bool blockUnknownLinks;
  final Map<String, int> used = {};

  @override
  Future<SafetyTextCheck> checkText(String text) async {
    final lower = text.toLowerCase();
    if (lower.contains(bannedSubstring.toLowerCase())) {
      return const SafetyTextCheck(
        allowed: false,
        code: 'NS062',
        message: 'That message contains restricted content.',
      );
    }
    if (blockUnknownLinks &&
        (lower.contains('http://') ||
            lower.contains('https://') ||
            lower.contains('www.')) &&
        !lower.contains('youtube.com') &&
        !lower.contains('youtu.be')) {
      return const SafetyTextCheck(
        allowed: false,
        code: 'NS063',
        message: 'That link is not allowed.',
      );
    }
    return const SafetyTextCheck(allowed: true);
  }

  @override
  Future<SafetyRateStatus> rateStatus(SafetyActionKey action) async {
    final key = action.wire;
    final usedCount = used[key] ?? 0;
    return SafetyRateStatus(
      actionKey: key,
      configured: true,
      maxCount: 20,
      windowSeconds: 3600,
      used: usedCount,
      remaining: (20 - usedCount).clamp(0, 20),
    );
  }
}

class SupabaseSafetyPolicyRepository implements SafetyPolicyRepository {
  SupabaseSafetyPolicyRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<SafetyTextCheck> checkText(String text) async {
    final raw = await _client.rpc(
      'check_safety_text',
      params: {'p_text': text},
    );
    if (raw is! Map) {
      return const SafetyTextCheck(allowed: false, message: 'Check failed.');
    }
    return SafetyTextCheck.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<SafetyRateStatus> rateStatus(SafetyActionKey action) async {
    final raw = await _client.rpc(
      'my_safety_rate_status',
      params: {'p_action_key': action.wire},
    );
    if (raw is! Map) {
      return SafetyRateStatus(actionKey: action.wire, configured: false);
    }
    return SafetyRateStatus.fromJson(Map<String, dynamic>.from(raw));
  }
}

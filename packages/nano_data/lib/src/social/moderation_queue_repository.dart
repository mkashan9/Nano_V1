import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// SAFE-02 platform moderation queue for learner reports.
class ModerationQueueRefused implements Exception {
  ModerationQueueRefused(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class ModerationQueueRepository {
  Future<List<ModerationQueueItem>> queue({String? status, int limit = 50});

  Future<ModerationQueueItem> claim(String reportId);

  Future<ModerationQueueItem> resolve(
    String reportId,
    ModerationResolution action, {
    required String note,
  });
}

class FakeModerationQueueRepository implements ModerationQueueRepository {
  FakeModerationQueueRepository({
    List<ModerationQueueItem>? seed,
    this.alwaysFail = false,
  }) : _items = [...?seed, if (seed == null) ..._defaultSeed];

  final bool alwaysFail;
  final List<ModerationQueueItem> _items;

  static final _defaultSeed = <ModerationQueueItem>[
    ModerationQueueItem(
      id: 'r0000000-0000-0000-0000-000000000001',
      category: ReportCategory.harassment,
      status: ReportStatus.open,
      peerLabel: 'sara',
      reporterLabel: 'ali',
      username: 'sara',
      details: 'Unwanted messages',
      alsoBlocked: true,
      evidence: const {
        'peer_label': 'sara',
        'username': 'sara',
        'context': 'user',
      },
      createdAt: DateTime.utc(2026, 8, 2),
    ),
    ModerationQueueItem(
      id: 'r0000000-0000-0000-0000-000000000002',
      category: ReportCategory.spam,
      status: ReportStatus.underReview,
      peerLabel: 'spammy',
      reporterLabel: 'fatima',
      username: 'spammy',
      evidence: const {
        'peer_label': 'spammy',
        'username': 'spammy',
        'context': 'user',
      },
      createdAt: DateTime.utc(2026, 8, 1),
    ),
  ];

  void _refuseIfNeeded() {
    if (alwaysFail) {
      throw ModerationQueueRefused(
        'Moderation queue is limited to platform staff.',
      );
    }
  }

  @override
  Future<List<ModerationQueueItem>> queue({
    String? status,
    int limit = 50,
  }) async {
    _refuseIfNeeded();
    final filtered = _items.where((item) {
      if (status == null) {
        return item.status == ReportStatus.open ||
            item.status == ReportStatus.underReview;
      }
      final wire = status.replaceAll('under_review', 'underReview');
      return item.status.name == wire;
    }).take(limit);
    return List.unmodifiable(filtered);
  }

  @override
  Future<ModerationQueueItem> claim(String reportId) async {
    _refuseIfNeeded();
    final index = _items.indexWhere((item) => item.id == reportId);
    if (index < 0) throw StateError('Report not found.');
    final current = _items[index];
    final next = ModerationQueueItem(
      id: current.id,
      category: current.category,
      status: current.status == ReportStatus.open
          ? ReportStatus.underReview
          : current.status,
      peerLabel: current.peerLabel,
      reporterLabel: current.reporterLabel,
      username: current.username,
      details: current.details,
      alsoBlocked: current.alsoBlocked,
      evidence: current.evidence,
      resolutionAction: current.resolutionAction,
      resolutionNote: current.resolutionNote,
      createdAt: current.createdAt,
      resolvedAt: current.resolvedAt,
    );
    _items[index] = next;
    return next;
  }

  @override
  Future<ModerationQueueItem> resolve(
    String reportId,
    ModerationResolution action, {
    required String note,
  }) async {
    _refuseIfNeeded();
    final index = _items.indexWhere((item) => item.id == reportId);
    if (index < 0) throw StateError('Report not found.');
    final current = _items[index];
    final next = ModerationQueueItem(
      id: current.id,
      category: current.category,
      status: action == ModerationResolution.dismiss
          ? ReportStatus.dismissed
          : ReportStatus.resolved,
      peerLabel: current.peerLabel,
      reporterLabel: current.reporterLabel,
      username: current.username,
      details: current.details,
      alsoBlocked: current.alsoBlocked,
      evidence: current.evidence,
      resolutionAction: action,
      resolutionNote: note,
      createdAt: current.createdAt,
      resolvedAt: DateTime.utc(2026, 8, 2, 12),
    );
    _items[index] = next;
    return next;
  }
}

class SupabaseModerationQueueRepository implements ModerationQueueRepository {
  SupabaseModerationQueueRepository(this._client);

  final SupabaseClient _client;

  Never _mapError(Object error) {
    final text = error.toString();
    if (text.contains('NS050') || text.contains('platform staff')) {
      throw ModerationQueueRefused(
        'Moderation queue is limited to platform staff.',
      );
    }
    throw error;
  }

  ModerationQueueItem _parse(dynamic raw) {
    if (raw is! Map) throw StateError('Report missing.');
    return ModerationQueueItem.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<List<ModerationQueueItem>> queue({
    String? status,
    int limit = 50,
  }) async {
    try {
      final raw = await _client.rpc(
        'list_user_reports_for_moderation',
        params: {'p_status': status, 'p_limit': limit},
      );
      if (raw is! Map) return const [];
      final items = raw['reports'];
      if (items is! List) return const [];
      return [
        for (final item in items)
          if (item is Map)
            ModerationQueueItem.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (error) {
      _mapError(error);
    }
  }

  @override
  Future<ModerationQueueItem> claim(String reportId) async {
    try {
      final raw = await _client.rpc(
        'claim_user_report',
        params: {'p_report_id': reportId},
      );
      return _parse(raw);
    } catch (error) {
      _mapError(error);
    }
  }

  @override
  Future<ModerationQueueItem> resolve(
    String reportId,
    ModerationResolution action, {
    required String note,
  }) async {
    try {
      final raw = await _client.rpc(
        'resolve_user_report',
        params: {
          'p_report_id': reportId,
          'p_action': action.name,
          'p_note': note,
        },
      );
      return _parse(raw);
    } catch (error) {
      _mapError(error);
    }
  }
}

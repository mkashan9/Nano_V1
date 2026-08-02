import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// SAFE-01 learner reports (queue resolution stays SAFE-02).
abstract class SafetyReportRepository {
  Future<SafetyReport> submitByQuery(
    String query,
    ReportDraft draft,
  );

  Future<SafetyReport> submitForPeer(
    String peerToken,
    ReportDraft draft,
  );

  Future<List<SafetyReport>> listMine();
}

class FakeSafetyReportRepository implements SafetyReportRepository {
  FakeSafetyReportRepository({List<SafetyReport>? reports})
      : _reports = [...?reports];

  final List<SafetyReport> _reports;
  final submittedQueries = <String>[];
  final submittedPeerTokens = <String>[];

  @override
  Future<SafetyReport> submitByQuery(String query, ReportDraft draft) async {
    submittedQueries.add(query.trim().toLowerCase());
    final report = SafetyReport(
      id: 'rpt-${_reports.length + 1}',
      category: draft.category,
      status: ReportStatus.open,
      peerLabel: query.trim().toLowerCase(),
      username: query.trim().toLowerCase(),
      details: draft.details,
      alsoBlocked: draft.alsoBlock,
      createdAt: DateTime.utc(2026, 8, 2),
    );
    _reports.insert(0, report);
    return report;
  }

  @override
  Future<SafetyReport> submitForPeer(
    String peerToken,
    ReportDraft draft,
  ) async {
    submittedPeerTokens.add(peerToken);
    final report = SafetyReport(
      id: 'rpt-${_reports.length + 1}',
      category: draft.category,
      status: ReportStatus.open,
      peerLabel: 'peer',
      details: draft.details,
      alsoBlocked: draft.alsoBlock,
      createdAt: DateTime.utc(2026, 8, 2),
    );
    _reports.insert(0, report);
    return report;
  }

  @override
  Future<List<SafetyReport>> listMine() async => List.unmodifiable(_reports);
}

class SupabaseSafetyReportRepository implements SafetyReportRepository {
  SupabaseSafetyReportRepository(this._client);

  final SupabaseClient _client;

  SafetyReport _parse(dynamic raw) {
    if (raw is! Map) throw StateError('Report missing.');
    return SafetyReport.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<SafetyReport> submitByQuery(String query, ReportDraft draft) async {
    final raw = await _client.rpc(
      'submit_user_report',
      params: {
        'p_query': query,
        'p_category': draft.categoryWire,
        'p_details': draft.details,
        'p_also_block': draft.alsoBlock,
      },
    );
    return _parse(raw);
  }

  @override
  Future<SafetyReport> submitForPeer(
    String peerToken,
    ReportDraft draft,
  ) async {
    final raw = await _client.rpc(
      'submit_user_report_for_peer',
      params: {
        'p_peer_token': peerToken,
        'p_category': draft.categoryWire,
        'p_details': draft.details,
        'p_also_block': draft.alsoBlock,
      },
    );
    return _parse(raw);
  }

  @override
  Future<List<SafetyReport>> listMine() async {
    final raw = await _client.rpc('my_user_reports');
    if (raw is! Map) return const [];
    final items = raw['reports'];
    if (items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map)
          SafetyReport.fromJson(Map<String, dynamic>.from(item)),
    ];
  }
}

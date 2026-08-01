import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// XP-01 read side of the trusted ledger.
///
/// Awards happen only on the server, inside the source-event transactions.
/// This repository never constructs a credit.
abstract class XpLedgerRepository {
  Future<XpBalance> balance();

  Future<List<XpLedgerEntry>> recent({int limit = 50});
}

class FakeXpLedgerRepository implements XpLedgerRepository {
  FakeXpLedgerRepository({
    this.balanceValue = const XpBalance(
      total: 560,
      today: 40,
      dailyCap: 200,
      remainingToday: 160,
    ),
    List<XpLedgerEntry>? entries,
  }) : _entries = [...?entries];

  XpBalance balanceValue;
  final List<XpLedgerEntry> _entries;

  @override
  Future<XpBalance> balance() async => balanceValue;

  @override
  Future<List<XpLedgerEntry>> recent({int limit = 50}) async {
    final sorted = [..._entries]
      ..sort((a, b) => b.awardedAt.compareTo(a.awardedAt));
    return sorted.take(limit).toList();
  }

  void credit(XpLedgerEntry entry) {
    _entries.add(entry);
    balanceValue = XpBalance(
      total: balanceValue.total + entry.amount,
      today: balanceValue.today + (entry.amount > 0 ? entry.amount : 0),
      dailyCap: balanceValue.dailyCap,
      remainingToday: (balanceValue.remainingToday - entry.amount)
          .clamp(0, balanceValue.dailyCap),
    );
  }
}

class SupabaseXpLedgerRepository implements XpLedgerRepository {
  SupabaseXpLedgerRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<XpBalance> balance() async {
    final raw = await _client.rpc('my_xp_balance');
    if (raw is Map<String, dynamic>) {
      return XpBalance.fromJson(raw);
    }
    if (raw is Map) {
      return XpBalance.fromJson(Map<String, dynamic>.from(raw));
    }
    return XpBalance.empty;
  }

  @override
  Future<List<XpLedgerEntry>> recent({int limit = 50}) async {
    final raw = await _client.rpc(
      'my_xp_ledger',
      params: {'p_limit': limit},
    );
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((row) => XpLedgerEntry.fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }
}

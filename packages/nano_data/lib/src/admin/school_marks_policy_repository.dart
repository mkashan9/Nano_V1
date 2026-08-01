import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// SCH-06 school-admin marks / result policies.
abstract class SchoolMarksPolicyRepository {
  Future<SchoolMarksPolicy> load();

  Future<SchoolMarksPolicy> save({
    required String attendanceMode,
    required double passingPercent,
    required bool allowBonus,
    required String reportCardFormat,
    List<GradeBand>? gradeBands,
  });

  Future<SchoolMarksPolicy> createPeriod({
    required String name,
    String? startsOn,
    String? endsOn,
  });

  Future<SchoolMarksPolicy> closePeriod({
    required String periodId,
    required String reason,
  });
}

class FakeSchoolMarksPolicyRepository implements SchoolMarksPolicyRepository {
  FakeSchoolMarksPolicyRepository({SchoolMarksPolicy? seed})
      : _policy = seed ??
            SchoolMarksPolicy(
              schoolId: TenancyFixtures.alphaSchoolId,
              attendanceMode: 'daily',
              passingPercent: 40,
              allowBonus: false,
              reportCardFormat: 'both',
              gradeBands: SchoolMarksPolicy.defaultGradeBands,
              periods: const [
                ResultPeriod(
                  id: 'period-1',
                  name: 'Term 1',
                  status: 'open',
                  startsOn: '2026-08-01',
                  endsOn: '2026-12-15',
                ),
              ],
            );

  SchoolMarksPolicy _policy;
  var alwaysFail = false;
  var saveCount = 0;
  final closeReasons = <String>[];

  @override
  Future<SchoolMarksPolicy> load() async {
    if (alwaysFail) throw StateError('Marks policy unavailable');
    return _policy;
  }

  @override
  Future<SchoolMarksPolicy> save({
    required String attendanceMode,
    required double passingPercent,
    required bool allowBonus,
    required String reportCardFormat,
    List<GradeBand>? gradeBands,
  }) async {
    if (alwaysFail) throw StateError('Save policy failed');
    final mode = attendanceMode.trim().toLowerCase();
    final format = reportCardFormat.trim().toLowerCase();
    if (mode != 'daily' && mode != 'session') {
      throw StateError('Attendance mode must be daily or session.');
    }
    if (passingPercent < 0 || passingPercent > 100) {
      throw StateError('Passing percent must be between 0 and 100.');
    }
    if (format != 'percent' && format != 'grade' && format != 'both') {
      throw StateError('Report card format must be percent, grade, or both.');
    }
    saveCount++;
    _policy = SchoolMarksPolicy(
      schoolId: _policy.schoolId,
      attendanceMode: mode,
      passingPercent: passingPercent,
      allowBonus: allowBonus,
      reportCardFormat: format,
      gradeBands: gradeBands ?? _policy.gradeBands,
      periods: _policy.periods,
    );
    return _policy;
  }

  @override
  Future<SchoolMarksPolicy> createPeriod({
    required String name,
    String? startsOn,
    String? endsOn,
  }) async {
    if (alwaysFail) throw StateError('Create period failed');
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw StateError('Period name is required.');
    if (_policy.periods.any((p) => p.name.toLowerCase() == trimmed.toLowerCase())) {
      throw StateError('Period name already exists.');
    }
    final period = ResultPeriod(
      id: 'period-${_policy.periods.length + 1}',
      name: trimmed,
      status: 'open',
      startsOn: startsOn,
      endsOn: endsOn,
    );
    _policy = SchoolMarksPolicy(
      schoolId: _policy.schoolId,
      attendanceMode: _policy.attendanceMode,
      passingPercent: _policy.passingPercent,
      allowBonus: _policy.allowBonus,
      reportCardFormat: _policy.reportCardFormat,
      gradeBands: _policy.gradeBands,
      periods: [..._policy.periods, period],
    );
    return _policy;
  }

  @override
  Future<SchoolMarksPolicy> closePeriod({
    required String periodId,
    required String reason,
  }) async {
    if (alwaysFail) throw StateError('Close period failed');
    if (reason.trim().isEmpty) throw StateError('A reason is required.');
    final index = _policy.periods.indexWhere((p) => p.id == periodId);
    if (index < 0) throw StateError('Result period not found in this school.');
    final current = _policy.periods[index];
    if (!current.isOpen) throw StateError('Result period is already closed.');
    closeReasons.add(reason.trim());
    final updated = List<ResultPeriod>.of(_policy.periods);
    updated[index] = ResultPeriod(
      id: current.id,
      name: current.name,
      status: 'closed',
      startsOn: current.startsOn,
      endsOn: current.endsOn,
      closedAt: '2026-08-02T00:00:00Z',
      closedReason: reason.trim(),
    );
    _policy = SchoolMarksPolicy(
      schoolId: _policy.schoolId,
      attendanceMode: _policy.attendanceMode,
      passingPercent: _policy.passingPercent,
      allowBonus: _policy.allowBonus,
      reportCardFormat: _policy.reportCardFormat,
      gradeBands: _policy.gradeBands,
      periods: updated,
    );
    return _policy;
  }
}

class SupabaseSchoolMarksPolicyRepository
    implements SchoolMarksPolicyRepository {
  SupabaseSchoolMarksPolicyRepository(this._client);

  final SupabaseClient _client;

  SchoolMarksPolicy _parse(dynamic raw) {
    if (raw is! Map) throw StateError('Marks policy unavailable.');
    return SchoolMarksPolicy.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<SchoolMarksPolicy> load() async {
    final raw = await _client.rpc('get_school_marks_policy');
    return _parse(raw);
  }

  @override
  Future<SchoolMarksPolicy> save({
    required String attendanceMode,
    required double passingPercent,
    required bool allowBonus,
    required String reportCardFormat,
    List<GradeBand>? gradeBands,
  }) async {
    final raw = await _client.rpc(
      'upsert_school_marks_policy',
      params: {
        'p_attendance_mode': attendanceMode,
        'p_passing_percent': passingPercent,
        'p_allow_bonus': allowBonus,
        'p_report_card_format': reportCardFormat,
        'p_grade_bands': gradeBands == null
            ? null
            : [for (final b in gradeBands) b.toJson()],
      },
    );
    return _parse(raw);
  }

  @override
  Future<SchoolMarksPolicy> createPeriod({
    required String name,
    String? startsOn,
    String? endsOn,
  }) async {
    final raw = await _client.rpc(
      'create_result_period',
      params: {
        'p_name': name,
        'p_starts_on': startsOn,
        'p_ends_on': endsOn,
      },
    );
    return _parse(raw);
  }

  @override
  Future<SchoolMarksPolicy> closePeriod({
    required String periodId,
    required String reason,
  }) async {
    final raw = await _client.rpc(
      'close_result_period',
      params: {
        'p_period_id': periodId,
        'p_reason': reason,
      },
    );
    return _parse(raw);
  }
}

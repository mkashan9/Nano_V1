import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// ADM-02 school create / status / first-admin assignment.
abstract class SchoolAdminRepository {
  Future<List<ManagedSchool>> list({String query = ''});

  Future<ManagedSchool> createSchool({
    required String code,
    required String name,
  });

  Future<ManagedSchool> setStatus({
    required String schoolId,
    required SchoolStatus status,
    required String reason,
  });

  /// Assigns the first active school_admin. Fails if one already exists.
  Future<ManagedSchool> assignFirstAdmin({
    required String schoolId,
    required String userId,
  });
}

class FakeSchoolAdminRepository implements SchoolAdminRepository {
  FakeSchoolAdminRepository({List<ManagedSchool>? seed})
      : _schools = List<ManagedSchool>.of(
          seed ??
              [
                ManagedSchool(
                  id: TenancyFixtures.alphaSchoolId,
                  code: TenancyFixtures.alpha.code,
                  name: TenancyFixtures.alpha.name,
                  status: SchoolStatus.active,
                  hasSchoolAdmin: true,
                  learnerCount: 30,
                  staffCount: 4,
                ),
                ManagedSchool(
                  id: TenancyFixtures.betaSchoolId,
                  code: TenancyFixtures.beta.code,
                  name: TenancyFixtures.beta.name,
                  status: SchoolStatus.active,
                  hasSchoolAdmin: false,
                  learnerCount: 18,
                  staffCount: 2,
                ),
              ],
        );

  final List<ManagedSchool> _schools;
  final statusReasons = <String>[];
  final assignedAdmins = <String>[];

  @override
  Future<List<ManagedSchool>> list({String query = ''}) async {
    final q = query.trim().toLowerCase();
    final rows = [
      for (final school in _schools)
        if (q.isEmpty ||
            school.name.toLowerCase().contains(q) ||
            school.code.toLowerCase().contains(q))
          school,
    ]..sort((a, b) => a.name.compareTo(b.name));
    return rows;
  }

  @override
  Future<ManagedSchool> createSchool({
    required String code,
    required String name,
  }) async {
    final normalized = SchoolCodeRules.normalize(code);
    if (!SchoolCodeRules.isValid(normalized)) {
      throw StateError('School code must be 3–16 uppercase letters or digits.');
    }
    if (name.trim().isEmpty) {
      throw StateError('School name is required.');
    }
    if (_schools.any((s) => s.code == normalized)) {
      throw StateError('That school code is already in use.');
    }
    final created = ManagedSchool(
      id: 'school-${_schools.length + 1}',
      code: normalized,
      name: name.trim(),
      status: SchoolStatus.active,
    );
    _schools.add(created);
    return created;
  }

  @override
  Future<ManagedSchool> setStatus({
    required String schoolId,
    required SchoolStatus status,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw StateError('A reason is required to change school status.');
    }
    final index = _schools.indexWhere((s) => s.id == schoolId);
    if (index == -1) throw StateError('School not found.');
    statusReasons.add(reason.trim());
    final current = _schools[index];
    final updated = ManagedSchool(
      id: current.id,
      code: current.code,
      name: current.name,
      status: status,
      hasSchoolAdmin: current.hasSchoolAdmin,
      learnerCount: current.learnerCount,
      staffCount: current.staffCount,
    );
    _schools[index] = updated;
    return updated;
  }

  @override
  Future<ManagedSchool> assignFirstAdmin({
    required String schoolId,
    required String userId,
  }) async {
    if (userId.trim().isEmpty) {
      throw StateError('A user id is required.');
    }
    final index = _schools.indexWhere((s) => s.id == schoolId);
    if (index == -1) throw StateError('School not found.');
    final current = _schools[index];
    if (current.hasSchoolAdmin) {
      throw StateError('This school already has an administrator.');
    }
    assignedAdmins.add('$schoolId:$userId');
    final updated = ManagedSchool(
      id: current.id,
      code: current.code,
      name: current.name,
      status: current.status,
      hasSchoolAdmin: true,
      learnerCount: current.learnerCount,
      staffCount: current.staffCount + 1,
    );
    _schools[index] = updated;
    return updated;
  }
}

class SupabaseSchoolAdminRepository implements SchoolAdminRepository {
  SupabaseSchoolAdminRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ManagedSchool>> list({String query = ''}) async {
    final raw = await _client.rpc(
      'list_managed_schools',
      params: {'p_query': query},
    );
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map>())
        ManagedSchool.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  @override
  Future<ManagedSchool> createSchool({
    required String code,
    required String name,
  }) async {
    final raw = await _client.rpc(
      'create_school',
      params: {'p_code': code, 'p_name': name},
    );
    return ManagedSchool.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<ManagedSchool> setStatus({
    required String schoolId,
    required SchoolStatus status,
    required String reason,
  }) async {
    final raw = await _client.rpc(
      'set_school_status',
      params: {
        'p_school_id': schoolId,
        'p_status': status.wireName,
        'p_reason': reason,
      },
    );
    return ManagedSchool.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<ManagedSchool> assignFirstAdmin({
    required String schoolId,
    required String userId,
  }) async {
    final raw = await _client.rpc(
      'assign_first_school_admin',
      params: {
        'p_school_id': schoolId,
        'p_user_id': userId,
      },
    );
    return ManagedSchool.fromJson(Map<String, dynamic>.from(raw as Map));
  }
}

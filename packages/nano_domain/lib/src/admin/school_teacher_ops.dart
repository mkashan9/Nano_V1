/// SCH-03 school-admin teacher directory row (email allowed for staff ops).
class SchoolTeacher {
  const SchoolTeacher({
    required this.id,
    required this.displayName,
    required this.email,
    required this.profileStatus,
    required this.membershipStatus,
  });

  final String id;
  final String displayName;
  final String email;
  final String profileStatus;
  final String membershipStatus;

  bool get isSuspended =>
      profileStatus == 'suspended' || membershipStatus == 'suspended';

  factory SchoolTeacher.fromJson(Map<String, dynamic> json) {
    // Staff-ops contact email is intentional; learner PII keys are not.
    final probe = Map<String, dynamic>.from(json)..remove('email');
    const forbidden = {
      'guardian',
      'guardian_contact',
      'phone',
      'attendance',
      'marks',
      'payment',
    };
    for (final key in probe.keys) {
      if (forbidden.contains(key.toLowerCase())) {
        throw StateError('Teacher row failed privacy review.');
      }
    }
    return SchoolTeacher(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileStatus: json['profile_status'] as String? ?? 'active',
      membershipStatus: json['membership_status'] as String? ?? 'active',
    );
  }
}

class TeacherCreateResult {
  const TeacherCreateResult({
    required this.teacher,
    required this.tempPassword,
    required this.teachers,
  });

  final SchoolTeacher teacher;
  final String tempPassword;
  final List<SchoolTeacher> teachers;

  factory TeacherCreateResult.fromJson(Map<String, dynamic> json) {
    final teacherRaw = json['teacher'];
    final listRaw = json['teachers'];
    return TeacherCreateResult(
      teacher: SchoolTeacher.fromJson(
        teacherRaw is Map
            ? Map<String, dynamic>.from(teacherRaw)
            : const {},
      ),
      tempPassword: json['temp_password'] as String? ?? '',
      teachers: [
        if (listRaw is List)
          for (final row in listRaw.whereType<Map>())
            SchoolTeacher.fromJson(Map<String, dynamic>.from(row)),
      ],
    );
  }
}

class TeacherImportPreview {
  const TeacherImportPreview({
    required this.okCount,
    required this.failCount,
    required this.okRows,
    required this.failedRows,
  });

  final int okCount;
  final int failCount;
  final List<TeacherImportRow> okRows;
  final List<TeacherImportFailure> failedRows;

  bool get canCommit => failCount == 0 && okCount > 0;

  factory TeacherImportPreview.fromJson(Map<String, dynamic> json) {
    final okRaw = json['ok_rows'];
    final failRaw = json['failed_rows'];
    return TeacherImportPreview(
      okCount: (json['ok_count'] as num?)?.toInt() ?? 0,
      failCount: (json['fail_count'] as num?)?.toInt() ?? 0,
      okRows: [
        if (okRaw is List)
          for (final row in okRaw.whereType<Map>())
            TeacherImportRow.fromJson(Map<String, dynamic>.from(row)),
      ],
      failedRows: [
        if (failRaw is List)
          for (final row in failRaw.whereType<Map>())
            TeacherImportFailure.fromJson(Map<String, dynamic>.from(row)),
      ],
    );
  }
}

class TeacherImportRow {
  const TeacherImportRow({
    required this.row,
    required this.displayName,
    required this.email,
  });

  final int row;
  final String displayName;
  final String email;

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'email': email,
      };

  factory TeacherImportRow.fromJson(Map<String, dynamic> json) {
    return TeacherImportRow(
      row: (json['row'] as num?)?.toInt() ?? 0,
      displayName: json['display_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

class TeacherImportFailure {
  const TeacherImportFailure({
    required this.row,
    required this.email,
    required this.error,
  });

  final int row;
  final String email;
  final String error;

  factory TeacherImportFailure.fromJson(Map<String, dynamic> json) {
    return TeacherImportFailure(
      row: (json['row'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );
  }
}

class TeacherImportCommitResult {
  const TeacherImportCommitResult({
    required this.committed,
    required this.message,
    required this.preview,
    required this.created,
    required this.teachers,
  });

  final bool committed;
  final String message;
  final TeacherImportPreview preview;
  final List<Map<String, dynamic>> created;
  final List<SchoolTeacher> teachers;

  factory TeacherImportCommitResult.fromJson(Map<String, dynamic> json) {
    final previewRaw = json['preview'];
    final createdRaw = json['created'];
    final teachersRaw = json['teachers'];
    return TeacherImportCommitResult(
      committed: json['committed'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      preview: TeacherImportPreview.fromJson(
        previewRaw is Map
            ? Map<String, dynamic>.from(previewRaw)
            : const {},
      ),
      created: [
        if (createdRaw is List)
          for (final row in createdRaw.whereType<Map>())
            Map<String, dynamic>.from(row),
      ],
      teachers: [
        if (teachersRaw is List)
          for (final row in teachersRaw.whereType<Map>())
            SchoolTeacher.fromJson(Map<String, dynamic>.from(row)),
      ],
    );
  }
}

/// Minimal CSV helper for teacher import (display_name,email).
abstract final class TeacherImportCsv {
  static const template = 'display_name,email\nMs Example,teacher2@school.example\n';

  static List<Map<String, String>> parse(String raw) {
    final lines = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];
    final start = lines.first.toLowerCase().contains('email') ? 1 : 0;
    final rows = <Map<String, String>>[];
    for (final line in lines.skip(start)) {
      final parts = _splitCsvLine(line);
      if (parts.isEmpty) continue;
      final name = parts.isNotEmpty ? parts[0].trim() : '';
      final email = parts.length > 1 ? parts[1].trim() : '';
      rows.add({'display_name': name, 'email': email});
    }
    return rows;
  }

  static List<String> _splitCsvLine(String line) {
    final out = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (ch == ',' && !inQuotes) {
        out.add(buf.toString());
        buf.clear();
        continue;
      }
      buf.write(ch);
    }
    out.add(buf.toString());
    return out;
  }
}

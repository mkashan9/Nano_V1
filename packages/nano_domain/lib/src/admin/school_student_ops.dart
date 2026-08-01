/// SCH-04 school-admin student directory row (email allowed for staff ops).
class SchoolStudent {
  const SchoolStudent({
    required this.id,
    required this.displayName,
    required this.email,
    required this.profileStatus,
    required this.membershipStatus,
    this.classId,
    this.className,
    this.sectionId,
    this.sectionName,
  });

  final String id;
  final String displayName;
  final String email;
  final String profileStatus;
  final String membershipStatus;
  final String? classId;
  final String? className;
  final String? sectionId;
  final String? sectionName;

  bool get isSuspended =>
      profileStatus == 'suspended' || membershipStatus == 'suspended';

  factory SchoolStudent.fromJson(Map<String, dynamic> json) {
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
        throw StateError('Student row failed privacy review.');
      }
    }
    return SchoolStudent(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileStatus: json['profile_status'] as String? ?? 'active',
      membershipStatus: json['membership_status'] as String? ?? 'active',
      classId: json['class_id'] as String?,
      className: json['class_name'] as String?,
      sectionId: json['section_id'] as String?,
      sectionName: json['section_name'] as String?,
    );
  }
}

class StudentCreateResult {
  const StudentCreateResult({
    required this.student,
    required this.tempPassword,
    required this.students,
  });

  final SchoolStudent student;
  final String tempPassword;
  final List<SchoolStudent> students;

  factory StudentCreateResult.fromJson(Map<String, dynamic> json) {
    final studentRaw = json['student'];
    final listRaw = json['students'];
    return StudentCreateResult(
      student: SchoolStudent.fromJson(
        studentRaw is Map
            ? Map<String, dynamic>.from(studentRaw)
            : const {},
      ),
      tempPassword: json['temp_password'] as String? ?? '',
      students: [
        if (listRaw is List)
          for (final row in listRaw.whereType<Map>())
            SchoolStudent.fromJson(Map<String, dynamic>.from(row)),
      ],
    );
  }
}

class StudentImportPreview {
  const StudentImportPreview({
    required this.okCount,
    required this.failCount,
    required this.okRows,
    required this.failedRows,
  });

  final int okCount;
  final int failCount;
  final List<StudentImportRow> okRows;
  final List<StudentImportFailure> failedRows;

  bool get canCommit => failCount == 0 && okCount > 0;

  factory StudentImportPreview.fromJson(Map<String, dynamic> json) {
    final okRaw = json['ok_rows'];
    final failRaw = json['failed_rows'];
    return StudentImportPreview(
      okCount: (json['ok_count'] as num?)?.toInt() ?? 0,
      failCount: (json['fail_count'] as num?)?.toInt() ?? 0,
      okRows: [
        if (okRaw is List)
          for (final row in okRaw.whereType<Map>())
            StudentImportRow.fromJson(Map<String, dynamic>.from(row)),
      ],
      failedRows: [
        if (failRaw is List)
          for (final row in failRaw.whereType<Map>())
            StudentImportFailure.fromJson(Map<String, dynamic>.from(row)),
      ],
    );
  }
}

class StudentImportRow {
  const StudentImportRow({
    required this.row,
    required this.displayName,
    required this.email,
    this.className,
    this.classId,
  });

  final int row;
  final String displayName;
  final String email;
  final String? className;
  final String? classId;

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'email': email,
        if (className != null && className!.isNotEmpty) 'class_name': className,
      };

  factory StudentImportRow.fromJson(Map<String, dynamic> json) {
    return StudentImportRow(
      row: (json['row'] as num?)?.toInt() ?? 0,
      displayName: json['display_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      className: json['class_name'] as String?,
      classId: json['class_id'] as String?,
    );
  }
}

class StudentImportFailure {
  const StudentImportFailure({
    required this.row,
    required this.email,
    required this.error,
  });

  final int row;
  final String email;
  final String error;

  factory StudentImportFailure.fromJson(Map<String, dynamic> json) {
    return StudentImportFailure(
      row: (json['row'] as num?)?.toInt() ?? 0,
      email: json['email'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );
  }
}

class StudentImportCommitResult {
  const StudentImportCommitResult({
    required this.committed,
    required this.message,
    required this.preview,
    required this.created,
    required this.students,
  });

  final bool committed;
  final String message;
  final StudentImportPreview preview;
  final List<Map<String, dynamic>> created;
  final List<SchoolStudent> students;

  factory StudentImportCommitResult.fromJson(Map<String, dynamic> json) {
    final previewRaw = json['preview'];
    final createdRaw = json['created'];
    final studentsRaw = json['students'];
    return StudentImportCommitResult(
      committed: json['committed'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      preview: StudentImportPreview.fromJson(
        previewRaw is Map
            ? Map<String, dynamic>.from(previewRaw)
            : const {},
      ),
      created: [
        if (createdRaw is List)
          for (final row in createdRaw.whereType<Map>())
            Map<String, dynamic>.from(row),
      ],
      students: [
        if (studentsRaw is List)
          for (final row in studentsRaw.whereType<Map>())
            SchoolStudent.fromJson(Map<String, dynamic>.from(row)),
      ],
    );
  }
}

/// CSV helper: display_name,email[,class_name]
abstract final class StudentImportCsv {
  static const template =
      'display_name,email,class_name\nAli Example,ali2@school.example,5-A\n';

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
      rows.add({
        'display_name': parts.isNotEmpty ? parts[0].trim() : '',
        'email': parts.length > 1 ? parts[1].trim() : '',
        'class_name': parts.length > 2 ? parts[2].trim() : '',
      });
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

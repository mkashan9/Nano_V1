import 'teacher_attendance.dart';

/// ATT-02 attendance CSV/Excel-compatible import models.
class AttendanceImportTemplate {
  const AttendanceImportTemplate({
    required this.assignmentId,
    required this.sessionDate,
    required this.periodKey,
    required this.classLabel,
    required this.subjectCode,
    required this.headers,
    required this.rows,
  });

  final String assignmentId;
  final String sessionDate;
  final String periodKey;
  final String classLabel;
  final String subjectCode;
  final List<String> headers;
  final List<Map<String, String>> rows;

  String get csvText {
    final header = headers.join(',');
    final body = [
      for (final row in rows)
        [
          row['student_user_id'] ?? '',
          _csvEscape(row['display_name'] ?? ''),
          row['status'] ?? 'present',
        ].join(','),
    ].join('\n');
    return '$header\n$body';
  }

  static String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  factory AttendanceImportTemplate.fromJson(Map<String, dynamic> json) {
    final headersRaw = json['headers'];
    final rowsRaw = json['rows'];
    return AttendanceImportTemplate(
      assignmentId: json['assignment_id'] as String? ?? '',
      sessionDate: '${json['session_date'] ?? ''}',
      periodKey: json['period_key'] as String? ?? 'daily',
      classLabel: json['class_label'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      headers: [
        if (headersRaw is List)
          for (final h in headersRaw) '$h'
        else ...['student_user_id', 'display_name', 'status'],
      ],
      rows: [
        if (rowsRaw is List)
          for (final row in rowsRaw.whereType<Map>())
            {
              'student_user_id': '${row['student_user_id'] ?? ''}',
              'display_name': '${row['display_name'] ?? ''}',
              'status': '${row['status'] ?? 'present'}',
            },
      ],
    );
  }
}

class AttendanceImportPreview {
  const AttendanceImportPreview({
    required this.jobId,
    required this.assignmentId,
    required this.sessionDate,
    required this.periodKey,
    required this.okCount,
    required this.failCount,
    required this.okRows,
    required this.failedRows,
    required this.canCommit,
  });

  final String jobId;
  final String assignmentId;
  final String sessionDate;
  final String periodKey;
  final int okCount;
  final int failCount;
  final List<AttendanceImportOkRow> okRows;
  final List<AttendanceImportFailure> failedRows;
  final bool canCommit;

  factory AttendanceImportPreview.fromJson(Map<String, dynamic> json) {
    final okRaw = json['ok_rows'];
    final failRaw = json['failed_rows'];
    return AttendanceImportPreview(
      jobId: json['job_id'] as String? ?? '',
      assignmentId: json['assignment_id'] as String? ?? '',
      sessionDate: '${json['session_date'] ?? ''}',
      periodKey: json['period_key'] as String? ?? 'daily',
      okCount: (json['ok_count'] as num?)?.toInt() ?? 0,
      failCount: (json['fail_count'] as num?)?.toInt() ?? 0,
      okRows: [
        if (okRaw is List)
          for (final row in okRaw.whereType<Map>())
            AttendanceImportOkRow.fromJson(Map<String, dynamic>.from(row)),
      ],
      failedRows: [
        if (failRaw is List)
          for (final row in failRaw.whereType<Map>())
            AttendanceImportFailure.fromJson(Map<String, dynamic>.from(row)),
      ],
      canCommit: json['can_commit'] as bool? ?? false,
    );
  }
}

class AttendanceImportOkRow {
  const AttendanceImportOkRow({
    required this.row,
    required this.studentUserId,
    required this.status,
  });

  final int row;
  final String studentUserId;
  final String status;

  Map<String, dynamic> toWire() => {
        'student_user_id': studentUserId,
        'status': status,
      };

  factory AttendanceImportOkRow.fromJson(Map<String, dynamic> json) {
    return AttendanceImportOkRow(
      row: (json['row'] as num?)?.toInt() ?? 0,
      studentUserId: json['student_user_id'] as String? ?? '',
      status: json['status'] as String? ?? 'present',
    );
  }
}

class AttendanceImportFailure {
  const AttendanceImportFailure({
    required this.row,
    required this.studentUserId,
    required this.error,
  });

  final int row;
  final String studentUserId;
  final String error;

  factory AttendanceImportFailure.fromJson(Map<String, dynamic> json) {
    return AttendanceImportFailure(
      row: (json['row'] as num?)?.toInt() ?? 0,
      studentUserId: json['student_user_id'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );
  }
}

class AttendanceImportCommitResult {
  const AttendanceImportCommitResult({
    required this.committed,
    required this.message,
    required this.preview,
    required this.grid,
  });

  final bool committed;
  final String message;
  final AttendanceImportPreview preview;
  final TeacherAttendanceGrid grid;

  factory AttendanceImportCommitResult.fromJson(Map<String, dynamic> json) {
    final previewRaw = json['preview'];
    final gridRaw = json['grid'];
    return AttendanceImportCommitResult(
      committed: json['committed'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      preview: AttendanceImportPreview.fromJson(
        previewRaw is Map ? Map<String, dynamic>.from(previewRaw) : const {},
      ),
      grid: TeacherAttendanceGrid.fromJson(
        gridRaw is Map ? Map<String, dynamic>.from(gridRaw) : const {},
      ),
    );
  }
}

abstract final class AttendanceImportCsv {
  static const headerLine = 'student_user_id,display_name,status';

  static List<Map<String, String>> parse(String raw) {
    final lines = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const [];
    final start =
        lines.first.toLowerCase().contains('student_user_id') ? 1 : 0;
    final rows = <Map<String, String>>[];
    for (final line in lines.skip(start)) {
      final parts = _splitCsvLine(line);
      if (parts.isEmpty) continue;
      rows.add({
        'student_user_id': parts.isNotEmpty ? parts[0].trim() : '',
        'display_name': parts.length > 1 ? parts[1].trim() : '',
        'status': parts.length > 2 ? parts[2].trim() : 'present',
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

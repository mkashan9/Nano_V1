import 'teacher_marks_grid.dart';

/// MRK-03 marks CSV/Excel-compatible import models.
class MarksImportTemplate {
  const MarksImportTemplate({
    required this.assessmentId,
    required this.assignmentId,
    required this.assessmentName,
    required this.totalMarks,
    required this.classLabel,
    required this.subjectCode,
    required this.headers,
    required this.rows,
  });

  final String assessmentId;
  final String assignmentId;
  final String assessmentName;
  final double totalMarks;
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
          row['status'] ?? 'scored',
          row['obtained_marks'] ?? '',
          _csvEscape(row['remarks'] ?? ''),
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

  factory MarksImportTemplate.fromJson(Map<String, dynamic> json) {
    final headersRaw = json['headers'];
    final rowsRaw = json['rows'];
    return MarksImportTemplate(
      assessmentId: json['assessment_id'] as String? ?? '',
      assignmentId: json['assignment_id'] as String? ?? '',
      assessmentName: json['assessment_name'] as String? ?? '',
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 0,
      classLabel: json['class_label'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      headers: [
        if (headersRaw is List)
          for (final h in headersRaw) '$h'
        else
          ...[
            'student_user_id',
            'display_name',
            'status',
            'obtained_marks',
            'remarks',
          ],
      ],
      rows: [
        if (rowsRaw is List)
          for (final row in rowsRaw.whereType<Map>())
            {
              'student_user_id': '${row['student_user_id'] ?? ''}',
              'display_name': '${row['display_name'] ?? ''}',
              'status': '${row['status'] ?? 'scored'}',
              'obtained_marks': '${row['obtained_marks'] ?? ''}',
              'remarks': '${row['remarks'] ?? ''}',
            },
      ],
    );
  }
}

class MarksImportPreview {
  const MarksImportPreview({
    required this.jobId,
    required this.assessmentId,
    required this.okCount,
    required this.failCount,
    required this.okRows,
    required this.failedRows,
    required this.canCommit,
  });

  final String jobId;
  final String assessmentId;
  final int okCount;
  final int failCount;
  final List<MarksImportOkRow> okRows;
  final List<MarksImportFailure> failedRows;
  final bool canCommit;

  factory MarksImportPreview.fromJson(Map<String, dynamic> json) {
    final okRaw = json['ok_rows'];
    final failRaw = json['failed_rows'];
    return MarksImportPreview(
      jobId: json['job_id'] as String? ?? '',
      assessmentId: json['assessment_id'] as String? ?? '',
      okCount: (json['ok_count'] as num?)?.toInt() ?? 0,
      failCount: (json['fail_count'] as num?)?.toInt() ?? 0,
      okRows: [
        if (okRaw is List)
          for (final row in okRaw.whereType<Map>())
            MarksImportOkRow.fromJson(Map<String, dynamic>.from(row)),
      ],
      failedRows: [
        if (failRaw is List)
          for (final row in failRaw.whereType<Map>())
            MarksImportFailure.fromJson(Map<String, dynamic>.from(row)),
      ],
      canCommit: json['can_commit'] as bool? ?? false,
    );
  }
}

class MarksImportOkRow {
  const MarksImportOkRow({
    required this.row,
    required this.studentUserId,
    required this.status,
    this.obtainedMarks,
    this.remarks = '',
  });

  final int row;
  final String studentUserId;
  final String status;
  final double? obtainedMarks;
  final String remarks;

  factory MarksImportOkRow.fromJson(Map<String, dynamic> json) {
    return MarksImportOkRow(
      row: (json['row'] as num?)?.toInt() ?? 0,
      studentUserId: json['student_user_id'] as String? ?? '',
      status: json['status'] as String? ?? 'scored',
      obtainedMarks: (json['obtained_marks'] as num?)?.toDouble(),
      remarks: json['remarks'] as String? ?? '',
    );
  }
}

class MarksImportFailure {
  const MarksImportFailure({
    required this.row,
    required this.studentUserId,
    required this.error,
  });

  final int row;
  final String studentUserId;
  final String error;

  factory MarksImportFailure.fromJson(Map<String, dynamic> json) {
    return MarksImportFailure(
      row: (json['row'] as num?)?.toInt() ?? 0,
      studentUserId: json['student_user_id'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );
  }
}

class MarksImportCommitResult {
  const MarksImportCommitResult({
    required this.committed,
    required this.message,
    required this.preview,
    required this.grid,
  });

  final bool committed;
  final String message;
  final MarksImportPreview preview;
  final TeacherMarksGrid grid;

  factory MarksImportCommitResult.fromJson(Map<String, dynamic> json) {
    final previewRaw = json['preview'];
    final gridRaw = json['grid'];
    return MarksImportCommitResult(
      committed: json['committed'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      preview: MarksImportPreview.fromJson(
        previewRaw is Map ? Map<String, dynamic>.from(previewRaw) : const {},
      ),
      grid: TeacherMarksGrid.fromJson(
        gridRaw is Map ? Map<String, dynamic>.from(gridRaw) : const {},
      ),
    );
  }
}

abstract final class MarksImportCsv {
  static const headerLine =
      'student_user_id,display_name,status,obtained_marks,remarks';

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
        'status': parts.length > 2 ? parts[2].trim() : 'scored',
        'obtained_marks': parts.length > 3 ? parts[3].trim() : '',
        'remarks': parts.length > 4 ? parts[4].trim() : '',
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

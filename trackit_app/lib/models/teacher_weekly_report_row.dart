/// A single weekly-report slot, from the reviewing instructor's side.
/// Weekly AR Submissions is a read-only compilation -- no status change
/// happens here, unlike Official Requirements.
class TeacherWeeklyReportRow {
  final int weekNumber;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final String status;
  final String? description;
  final DateTime? submittedAt;

  const TeacherWeeklyReportRow({
    required this.weekNumber,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.status,
    this.description,
    this.submittedAt,
  });

  factory TeacherWeeklyReportRow.fromJson(Map<String, dynamic> json) {
    return TeacherWeeklyReportRow(
      weekNumber: json['weekNumber'] as int,
      weekStartDate: DateTime.parse(json['weekStartDate'] as String),
      weekEndDate: DateTime.parse(json['weekEndDate'] as String),
      status: json['status'] as String,
      description: json['description'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
    );
  }
}

/// One row in the Weekly AR Submissions student list.
class TeacherWeeklyReportStudentSummary {
  final int id;
  final String name;
  final String? avatarUrl;
  final String course;
  final String section;
  final int expectedWeeks;
  final int submittedWeeks;

  const TeacherWeeklyReportStudentSummary({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.course,
    required this.section,
    required this.expectedWeeks,
    required this.submittedWeeks,
  });

  factory TeacherWeeklyReportStudentSummary.fromJson(Map<String, dynamic> json) {
    return TeacherWeeklyReportStudentSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      course: json['course'] as String,
      section: json['section'] as String,
      expectedWeeks: json['expectedWeeks'] as int,
      submittedWeeks: json['submittedWeeks'] as int,
    );
  }
}

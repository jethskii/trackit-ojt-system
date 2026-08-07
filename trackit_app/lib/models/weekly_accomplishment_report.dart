enum WeeklyReportStatus { missing, submitted, approved, rejected }

/// A student's Weekly Accomplishment Report (AR) -- one recurring upload
/// slot per OJT week, generated from the student's OJT Start Date through
/// the current week. Purely a record/compilation of that week's
/// accomplishments: no hours field, no link to attendance or hours
/// calculation.
class WeeklyAccomplishmentReport {
  final int weekNumber;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final WeeklyReportStatus status;
  final String? description;
  final List<String> attachments;
  final DateTime? submittedAt;

  /// Instructor feedback explaining a rejection. There's no Instructor
  /// module yet to actually write these, so this is always null for now
  /// -- the field and its UI are ready for when that exists.
  final String? remarks;

  const WeeklyAccomplishmentReport({
    required this.weekNumber,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.status,
    this.description,
    this.attachments = const [],
    this.submittedAt,
    this.remarks,
  });

  bool get hasSubmission => status != WeeklyReportStatus.missing;

  static WeeklyReportStatus _statusFromDb(String value) {
    switch (value) {
      case 'submitted':
        return WeeklyReportStatus.submitted;
      case 'approved':
        return WeeklyReportStatus.approved;
      case 'rejected':
        return WeeklyReportStatus.rejected;
      default:
        return WeeklyReportStatus.missing;
    }
  }

  factory WeeklyAccomplishmentReport.fromJson(Map<String, dynamic> json) {
    return WeeklyAccomplishmentReport(
      weekNumber: json['weekNumber'] as int,
      weekStartDate: DateTime.parse(json['weekStartDate'] as String),
      weekEndDate: DateTime.parse(json['weekEndDate'] as String),
      status: _statusFromDb(json['status'] as String),
      description: json['description'] as String?,
      attachments:
          (json['attachments'] as List<dynamic>?)?.cast<String>() ?? const [],
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
      remarks: json['remarks'] as String?,
    );
  }
}

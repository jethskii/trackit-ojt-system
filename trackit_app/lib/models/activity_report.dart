enum ActivityReportStatus { draft, submitted, reviewed, approved, needsRevision }

class ActivityReport {
  final String id;
  final String title;
  final DateTime date;
  final String company;
  final double hoursRendered;
  final String description;
  final List<String> attachments;
  final ActivityReportStatus status;

  const ActivityReport({
    required this.id,
    required this.title,
    required this.date,
    required this.company,
    required this.hoursRendered,
    required this.description,
    this.attachments = const [],
    required this.status,
  });

  static ActivityReportStatus _statusFromDb(String value) {
    switch (value) {
      case 'draft':
        return ActivityReportStatus.draft;
      case 'submitted':
        return ActivityReportStatus.submitted;
      case 'reviewed':
        return ActivityReportStatus.reviewed;
      case 'approved':
        return ActivityReportStatus.approved;
      case 'needs_revision':
        return ActivityReportStatus.needsRevision;
      default:
        return ActivityReportStatus.draft;
    }
  }

  static String statusToDb(ActivityReportStatus status) {
    switch (status) {
      case ActivityReportStatus.draft:
        return 'draft';
      case ActivityReportStatus.submitted:
        return 'submitted';
      case ActivityReportStatus.reviewed:
        return 'reviewed';
      case ActivityReportStatus.approved:
        return 'approved';
      case ActivityReportStatus.needsRevision:
        return 'needs_revision';
    }
  }

  factory ActivityReport.fromJson(Map<String, dynamic> json) {
    return ActivityReport(
      id: json['id'].toString(),
      title: json['title'] as String,
      date: DateTime.parse(json['report_date'] as String),
      company: json['company_name'] as String? ?? 'Not assigned yet',
      hoursRendered: double.parse(json['hours_rendered'].toString()),
      description: json['description'] as String? ?? '',
      attachments:
          (json['attachments'] as List<dynamic>?)?.cast<String>() ?? const [],
      status: _statusFromDb(json['status'] as String),
    );
  }

  ActivityReport copyWith({
    String? title,
    DateTime? date,
    String? company,
    double? hoursRendered,
    String? description,
    List<String>? attachments,
    ActivityReportStatus? status,
  }) {
    return ActivityReport(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      company: company ?? this.company,
      hoursRendered: hoursRendered ?? this.hoursRendered,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
    );
  }
}

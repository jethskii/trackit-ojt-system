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

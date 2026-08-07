enum CorrectionStatus { pending, approved, rejected }

/// A student's attendance correction request, from the reviewing
/// instructor's side.
class TeacherCorrectionRequest {
  final int id;
  final int studentId;
  final String studentName;
  final String? avatarUrl;
  final DateTime workDate;
  final String reason;
  final String? attachmentFileName;
  final CorrectionStatus status;
  final String? reviewerNote;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  const TeacherCorrectionRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.avatarUrl,
    required this.workDate,
    required this.reason,
    this.attachmentFileName,
    required this.status,
    this.reviewerNote,
    required this.submittedAt,
    this.reviewedAt,
  });

  factory TeacherCorrectionRequest.fromJson(Map<String, dynamic> json) {
    return TeacherCorrectionRequest(
      id: json['id'] as int,
      studentId: json['studentId'] as int,
      studentName: json['studentName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      workDate: DateTime.parse(json['workDate'] as String),
      reason: json['reason'] as String,
      attachmentFileName: json['attachmentFileName'] as String?,
      status: CorrectionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CorrectionStatus.pending,
      ),
      reviewerNote: json['reviewerNote'] as String?,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt'] as String) : null,
    );
  }
}

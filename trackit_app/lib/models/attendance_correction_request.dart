enum CorrectionRequestStatus { pending, approved, rejected }

/// A student's request to fix an attendance record (e.g. a missed clock
/// out, wrong time) -- routed to an instructor for approve/reject. There's
/// no Instructor module yet to actually review these, so every request
/// stays [CorrectionRequestStatus.pending] until that exists; the field
/// and its UI are ready for when it does.
class AttendanceCorrectionRequest {
  final String id;
  final DateTime workDate;
  final String reason;
  final String? attachmentFileName;
  final CorrectionRequestStatus status;
  final DateTime submittedAt;
  final String? reviewerNote;

  const AttendanceCorrectionRequest({
    required this.id,
    required this.workDate,
    required this.reason,
    this.attachmentFileName,
    required this.status,
    required this.submittedAt,
    this.reviewerNote,
  });

  static CorrectionRequestStatus _statusFromDb(String value) {
    switch (value) {
      case 'approved':
        return CorrectionRequestStatus.approved;
      case 'rejected':
        return CorrectionRequestStatus.rejected;
      default:
        return CorrectionRequestStatus.pending;
    }
  }

  factory AttendanceCorrectionRequest.fromJson(Map<String, dynamic> json) {
    return AttendanceCorrectionRequest(
      id: json['id'].toString(),
      workDate: DateTime.parse(json['workDate'] as String),
      reason: json['reason'] as String,
      attachmentFileName: json['attachmentFileName'] as String?,
      status: _statusFromDb(json['status'] as String),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      reviewerNote: json['reviewerNote'] as String?,
    );
  }
}

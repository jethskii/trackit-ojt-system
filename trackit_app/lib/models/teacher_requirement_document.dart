import 'ojt_requirement_doc.dart';

/// A requirement document as seen by the reviewing instructor -- same
/// status vocabulary as the student's own [OjtRequirementDoc], plus the
/// fields a reviewer needs: which submission row to act on, the uploaded
/// file's URL (to actually view it), and timestamps.
class TeacherRequirementDocument {
  final String id;
  final String? submissionId;
  final String name;
  final String description;
  final RequirementDocStatus status;
  final String? uploadedFileName;
  final String? uploadedFileUrl;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? remarks;

  const TeacherRequirementDocument({
    required this.id,
    this.submissionId,
    required this.name,
    required this.description,
    required this.status,
    this.uploadedFileName,
    this.uploadedFileUrl,
    this.submittedAt,
    this.reviewedAt,
    this.remarks,
  });

  bool get canReview => submissionId != null && status == RequirementDocStatus.submitted;

  factory TeacherRequirementDocument.fromJson(Map<String, dynamic> json) {
    return TeacherRequirementDocument(
      id: json['id'].toString(),
      submissionId: json['submissionId']?.toString(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      status: RequirementDocStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RequirementDocStatus.missing,
      ),
      uploadedFileName: json['uploadedFileName'] as String?,
      uploadedFileUrl: json['uploadedFileUrl'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      remarks: json['remarks'] as String?,
    );
  }
}

import 'ojt_requirement_doc.dart';

/// An Additional Requirement (instructor-created) merged with one
/// student's submission against it -- the per-student "Additional
/// Requirements" tab uses this, mirroring [TeacherRequirementDocument]
/// but for custom_requirements instead of the fixed template set.
class TeacherCustomRequirementSubmission {
  final String id;
  final String? submissionId;
  final String name;
  final String description;
  final DateTime? deadline;
  final RequirementDocStatus status;
  final String? uploadedFileName;
  final String? uploadedFileUrl;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? remarks;

  const TeacherCustomRequirementSubmission({
    required this.id,
    this.submissionId,
    required this.name,
    required this.description,
    this.deadline,
    required this.status,
    this.uploadedFileName,
    this.uploadedFileUrl,
    this.submittedAt,
    this.reviewedAt,
    this.remarks,
  });

  bool get canReview => submissionId != null && status == RequirementDocStatus.submitted;

  factory TeacherCustomRequirementSubmission.fromJson(Map<String, dynamic> json) {
    return TeacherCustomRequirementSubmission(
      id: json['id'].toString(),
      submissionId: json['submissionId']?.toString(),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
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

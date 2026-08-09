import 'ojt_requirement_doc.dart';

/// An instructor-created "Additional Requirement", as the student sees
/// it -- same submit/status flow as the fixed Official Requirements, just
/// sourced from custom_requirements instead of ojt_requirement_templates.
class CustomRequirement {
  final String id;
  final String name;
  final String description;
  final DateTime? deadline;
  final RequirementDocStatus status;
  final String? templateUrl;
  final String? templateName;
  final String? uploadedFileName;
  final String? uploadedFileUrl;
  final DateTime? submittedAt;
  final String? remarks;

  const CustomRequirement({
    required this.id,
    required this.name,
    required this.description,
    this.deadline,
    required this.status,
    this.templateUrl,
    this.templateName,
    this.uploadedFileName,
    this.uploadedFileUrl,
    this.submittedAt,
    this.remarks,
  });

  factory CustomRequirement.fromJson(Map<String, dynamic> json) {
    return CustomRequirement(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      status: RequirementDocStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RequirementDocStatus.missing,
      ),
      templateUrl: json['templateUrl'] as String?,
      templateName: json['templateName'] as String?,
      uploadedFileName: json['uploadedFileName'] as String?,
      uploadedFileUrl: json['uploadedFileUrl'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
      remarks: json['remarks'] as String?,
    );
  }

  /// Adapts this into the shape [RequirementDocTile] already knows how to
  /// render, so Additional Requirements reuses the same tile as Official
  /// Requirements instead of a near-duplicate widget.
  OjtRequirementDoc toDoc() {
    return OjtRequirementDoc(
      id: id,
      name: name,
      description: description,
      status: status,
      deadline: deadline,
      hasTemplate: templateUrl != null,
      templateUrl: templateUrl,
      templateName: templateName,
      uploadedFileName: uploadedFileName,
      uploadedFileUrl: uploadedFileUrl,
      submittedAt: submittedAt,
      remarks: remarks,
    );
  }
}

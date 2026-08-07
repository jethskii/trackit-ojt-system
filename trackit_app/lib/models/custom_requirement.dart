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
  final String? uploadedFileName;
  final String? remarks;

  const CustomRequirement({
    required this.id,
    required this.name,
    required this.description,
    this.deadline,
    required this.status,
    this.uploadedFileName,
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
      uploadedFileName: json['uploadedFileName'] as String?,
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
      uploadedFileName: uploadedFileName,
      remarks: remarks,
    );
  }
}

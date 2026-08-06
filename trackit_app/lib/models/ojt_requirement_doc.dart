enum RequirementDocStatus { missing, pending, submitted, approved, rejected }

class OjtRequirementDoc {
  final String id;
  final String name;
  final String description;
  final RequirementDocStatus status;
  final DateTime? deadline;
  final bool hasTemplate;
  final String? uploadedFileName;

  const OjtRequirementDoc({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.deadline,
    this.hasTemplate = false,
    this.uploadedFileName,
  });

  OjtRequirementDoc copyWith({
    RequirementDocStatus? status,
    String? uploadedFileName,
  }) {
    return OjtRequirementDoc(
      id: id,
      name: name,
      description: description,
      status: status ?? this.status,
      deadline: deadline,
      hasTemplate: hasTemplate,
      uploadedFileName: uploadedFileName ?? this.uploadedFileName,
    );
  }
}

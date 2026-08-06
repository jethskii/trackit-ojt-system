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

  factory OjtRequirementDoc.fromJson(Map<String, dynamic> json) {
    return OjtRequirementDoc(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String,
      status: RequirementDocStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RequirementDocStatus.missing,
      ),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      hasTemplate: json['hasTemplate'] as bool? ?? false,
      uploadedFileName: json['uploadedFileName'] as String?,
    );
  }

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

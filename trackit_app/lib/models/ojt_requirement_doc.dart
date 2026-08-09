enum RequirementDocStatus { missing, pending, submitted, approved, rejected }

class OjtRequirementDoc {
  final String id;
  final String name;
  final String description;
  final RequirementDocStatus status;
  final DateTime? deadline;
  final bool hasTemplate;
  final String? templateUrl;
  final String? templateName;
  final String? uploadedFileName;
  final String? uploadedFileUrl;
  final DateTime? submittedAt;

  /// Instructor feedback explaining a rejection/re-upload request.
  final String? remarks;

  const OjtRequirementDoc({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.deadline,
    this.hasTemplate = false,
    this.templateUrl,
    this.templateName,
    this.uploadedFileName,
    this.uploadedFileUrl,
    this.submittedAt,
    this.remarks,
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

  OjtRequirementDoc copyWith({
    RequirementDocStatus? status,
    String? uploadedFileName,
    String? uploadedFileUrl,
    DateTime? submittedAt,
  }) {
    return OjtRequirementDoc(
      id: id,
      name: name,
      description: description,
      status: status ?? this.status,
      deadline: deadline,
      hasTemplate: hasTemplate,
      templateUrl: templateUrl,
      templateName: templateName,
      uploadedFileName: uploadedFileName ?? this.uploadedFileName,
      uploadedFileUrl: uploadedFileUrl ?? this.uploadedFileUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      remarks: remarks,
    );
  }
}

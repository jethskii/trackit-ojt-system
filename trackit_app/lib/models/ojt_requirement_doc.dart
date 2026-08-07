enum RequirementDocStatus { missing, pending, submitted, approved, rejected }

class OjtRequirementDoc {
  final String id;
  final String name;
  final String description;
  final RequirementDocStatus status;
  final DateTime? deadline;
  final bool hasTemplate;
  final String? uploadedFileName;

  /// Instructor feedback explaining a rejection/re-upload request. There's
  /// no Instructor module yet to actually write these, so this is always
  /// null for now -- the field and its UI are ready for when that exists.
  final String? remarks;

  const OjtRequirementDoc({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.deadline,
    this.hasTemplate = false,
    this.uploadedFileName,
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
      uploadedFileName: json['uploadedFileName'] as String?,
      remarks: json['remarks'] as String?,
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
      remarks: remarks,
    );
  }
}

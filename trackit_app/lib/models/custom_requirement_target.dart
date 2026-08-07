class CustomRequirementTarget {
  final int classId;
  final String program;
  final String section;

  const CustomRequirementTarget({
    required this.classId,
    required this.program,
    required this.section,
  });

  factory CustomRequirementTarget.fromJson(Map<String, dynamic> json) {
    return CustomRequirementTarget(
      classId: json['classId'] as int,
      program: json['program'] as String,
      section: json['section'] as String,
    );
  }
}

/// An Additional Requirement as the instructor who created it sees it --
/// its definition and which section(s) it's targeted at, not tied to any
/// one student's submission.
class CustomRequirementDefinition {
  final int id;
  final String title;
  final String description;
  final DateTime? deadline;
  final List<CustomRequirementTarget> targets;
  final DateTime createdAt;

  const CustomRequirementDefinition({
    required this.id,
    required this.title,
    required this.description,
    this.deadline,
    required this.targets,
    required this.createdAt,
  });

  factory CustomRequirementDefinition.fromJson(Map<String, dynamic> json) {
    return CustomRequirementDefinition(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      targets: (json['targets'] as List<dynamic>)
          .map((t) => CustomRequirementTarget.fromJson(t as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

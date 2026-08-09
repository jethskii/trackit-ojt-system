/// A single Official Requirement's template, as seen on the instructor's
/// "Manage Templates" screen -- separate from [TeacherRequirementDocument]
/// since this is about the department-wide template catalog, not any one
/// student's submission.
class TeacherOfficialTemplateItem {
  final int id;
  final String name;
  final String description;
  final bool hasTemplate;
  final String? templateUrl;
  final String? templateName;

  const TeacherOfficialTemplateItem({
    required this.id,
    required this.name,
    required this.description,
    required this.hasTemplate,
    this.templateUrl,
    this.templateName,
  });

  factory TeacherOfficialTemplateItem.fromJson(Map<String, dynamic> json) {
    return TeacherOfficialTemplateItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      hasTemplate: json['hasTemplate'] as bool? ?? false,
      templateUrl: json['templateUrl'] as String?,
      templateName: json['templateName'] as String?,
    );
  }
}

class TeacherOfficialTemplatePhase {
  final int id;
  final int order;
  final String title;
  final String description;
  final List<TeacherOfficialTemplateItem> templates;

  const TeacherOfficialTemplatePhase({
    required this.id,
    required this.order,
    required this.title,
    required this.description,
    required this.templates,
  });

  factory TeacherOfficialTemplatePhase.fromJson(Map<String, dynamic> json) {
    return TeacherOfficialTemplatePhase(
      id: json['id'] as int,
      order: (json['order'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      templates: (json['templates'] as List<dynamic>)
          .map((t) => TeacherOfficialTemplateItem.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

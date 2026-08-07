class Teacher {
  final String id;
  final String name;
  final String honorific;
  final String program;
  final List<String> sections;

  const Teacher({
    required this.id,
    required this.name,
    required this.honorific,
    required this.program,
    required this.sections,
  });

  String get displayName => '$honorific $name';
  String get sectionsLabel => sections.join(', ');
}

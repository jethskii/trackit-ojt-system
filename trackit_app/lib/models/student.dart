class Student {
  final String name;
  final String course;
  final String section;
  final String companyName;
  final String? avatarUrl;

  const Student({
    required this.name,
    required this.course,
    required this.section,
    required this.companyName,
    this.avatarUrl,
  });

  String get courseAndSection => '$course - $section';
}

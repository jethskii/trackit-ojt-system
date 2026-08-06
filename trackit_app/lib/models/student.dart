import 'student_profile.dart';

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

  factory Student.fromProfile(StudentProfile profile) {
    return Student(
      name: profile.fullName,
      course: profile.course,
      section: profile.section,
      companyName: profile.company?.name ?? 'Not assigned yet',
      avatarUrl: profile.avatarUrl,
    );
  }

  String get courseAndSection => '$course - $section';
}

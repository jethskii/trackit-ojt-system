/// A class (Program + Section + Academic Year) an instructor created --
/// students join it with [activationCode]. Normally admin-generated;
/// since there's no Admin module yet, the instructor creates their own.
class InstructorClass {
  final int id;
  final String program;
  final String section;
  final String academicYear;
  final String activationCode;
  final int studentCount;

  const InstructorClass({
    required this.id,
    required this.program,
    required this.section,
    required this.academicYear,
    required this.activationCode,
    required this.studentCount,
  });

  factory InstructorClass.fromJson(Map<String, dynamic> json) {
    return InstructorClass(
      id: json['id'] as int,
      program: json['program'] as String,
      section: json['section'] as String,
      academicYear: json['academicYear'] as String,
      activationCode: json['activationCode'] as String,
      studentCount: json['studentCount'] as int,
    );
  }
}

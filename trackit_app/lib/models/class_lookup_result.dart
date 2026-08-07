/// What a Class Activation Code resolves to, shown at registration time
/// so the student can confirm they're joining the right class before
/// submitting ("You're joining: BSIT - 3F under Ma'am Althea").
class ClassLookupResult {
  final String program;
  final String section;
  final String academicYear;
  final String instructorName;

  const ClassLookupResult({
    required this.program,
    required this.section,
    required this.academicYear,
    required this.instructorName,
  });

  factory ClassLookupResult.fromJson(Map<String, dynamic> json) {
    return ClassLookupResult(
      program: json['program'] as String,
      section: json['section'] as String,
      academicYear: json['academicYear'] as String,
      instructorName: json['instructorName'] as String,
    );
  }
}

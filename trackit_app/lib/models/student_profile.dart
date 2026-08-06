import 'hte_company.dart';
import 'staff_contact.dart';

class StudentProfile {
  final String fullName;
  final String studentNumber;
  final String course;
  final String yearLevel;
  final String section;
  final String school;
  final String email;
  final String mobileNumber;
  final String? avatarUrl;

  /// Null until the department assigns an adviser/company/supervisor.
  final StaffContact? adviser;
  final HteCompany? company;
  final StaffContact? supervisor;

  const StudentProfile({
    required this.fullName,
    required this.studentNumber,
    required this.course,
    required this.yearLevel,
    required this.section,
    required this.school,
    required this.email,
    required this.mobileNumber,
    this.avatarUrl,
    this.adviser,
    this.company,
    this.supervisor,
  });

  StudentProfile copyWith({String? avatarUrl}) {
    return StudentProfile(
      fullName: fullName,
      studentNumber: studentNumber,
      course: course,
      yearLevel: yearLevel,
      section: section,
      school: school,
      email: email,
      mobileNumber: mobileNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      adviser: adviser,
      company: company,
      supervisor: supervisor,
    );
  }
}

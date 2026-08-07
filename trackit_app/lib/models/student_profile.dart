import 'company_details.dart';
import 'staff_contact.dart';

class StudentProfile {
  /// This is a single-department app (DCSE at Dalubhasaan ng Lungsod ng
  /// San Pablo), so "school" is a constant rather than a per-student
  /// database column.
  static const String defaultSchool = 'Dalubhasaan ng Lungsod ng San Pablo';

  final String fullName;
  final String studentNumber;
  final String course;
  final String yearLevel;
  final String section;
  final String school;
  final String email;
  final String mobileNumber;
  final String? avatarUrl;

  /// Null until the department assigns an adviser, or the student
  /// completes the Confirm Company Details step (which also sets
  /// [supervisor], since that form collects both together).
  final StaffContact? adviser;
  final CompanyDetails? company;
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

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      fullName: json['fullName'] as String,
      studentNumber: json['studentNumber'] as String? ?? 'Not set',
      course: json['course'] as String,
      yearLevel: json['yearLevel'] as String? ?? 'Not set',
      section: json['section'] as String,
      school: defaultSchool,
      email: json['email'] as String,
      mobileNumber: json['mobileNumber'] as String? ?? 'Not set',
      avatarUrl: json['avatarUrl'] as String?,
      adviser: json['adviser'] != null
          ? StaffContact.fromJson(json['adviser'] as Map<String, dynamic>)
          : null,
      company: json['company'] != null
          ? CompanyDetails.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      supervisor: json['supervisor'] != null
          ? StaffContact.fromJson(json['supervisor'] as Map<String, dynamic>)
          : null,
    );
  }

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

  /// Applies the Confirm Company Details form: sets [company] and derives
  /// [supervisor] from the same form (name + contact number it collects).
  StudentProfile withCompanyDetails(CompanyDetails details) {
    return StudentProfile(
      fullName: fullName,
      studentNumber: studentNumber,
      course: course,
      yearLevel: yearLevel,
      section: section,
      school: school,
      email: email,
      mobileNumber: mobileNumber,
      avatarUrl: avatarUrl,
      adviser: adviser,
      company: details,
      supervisor: StaffContact(
        name: details.supervisorName,
        role: 'HR Supervisor',
        email: '',
        phone: details.contactNumber,
      ),
    );
  }
}

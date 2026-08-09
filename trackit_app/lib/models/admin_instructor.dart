/// One row in the Faculty/Instructors list -- mirrors AdminClassSummary's
/// role for the Sections list.
class AdminInstructorSummary {
  final int id;
  final String name;
  final String instructorNumber;
  final String? avatarUrl;

  /// Admin-controlled enable/disable (Revoke Access / Reactivate) --
  /// independent of whether the account has been activated yet.
  final String status;

  /// Whether the instructor has claimed their account (set a password
  /// via the Instructor Activation Code) or is still Pending.
  final String accountStatus;

  const AdminInstructorSummary({
    required this.id,
    required this.name,
    required this.instructorNumber,
    this.avatarUrl,
    required this.status,
    required this.accountStatus,
  });

  bool get isActive => status == 'active';
  bool get isActivated => accountStatus == 'activated';

  factory AdminInstructorSummary.fromJson(Map<String, dynamic> json) {
    return AdminInstructorSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      instructorNumber: json['instructorNumber'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String,
      accountStatus: json['accountStatus'] as String,
    );
  }
}

class AdminAssignedSection {
  final int id;
  final String program;
  final String section;
  final String academicYear;
  final int studentCount;

  const AdminAssignedSection({
    required this.id,
    required this.program,
    required this.section,
    required this.academicYear,
    required this.studentCount,
  });

  factory AdminAssignedSection.fromJson(Map<String, dynamic> json) {
    return AdminAssignedSection(
      id: json['id'] as int,
      program: json['program'] as String,
      section: json['section'] as String,
      academicYear: json['academicYear'] as String,
      studentCount: json['studentCount'] as int,
    );
  }
}

/// A student enrolled under one of the instructor's assigned sections --
/// same underlying data as AdminClassStudent, plus which section they're
/// in (an instructor's enrolled list can span more than one section).
class AdminInstructorStudent {
  final int id;
  final String name;
  final String email;
  final String? studentNumber;
  final String section;
  final String accountStatus;

  const AdminInstructorStudent({
    required this.id,
    required this.name,
    required this.email,
    this.studentNumber,
    required this.section,
    required this.accountStatus,
  });

  factory AdminInstructorStudent.fromJson(Map<String, dynamic> json) {
    return AdminInstructorStudent(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      studentNumber: json['studentNumber'] as String?,
      section: json['section'] as String,
      accountStatus: json['accountStatus'] as String,
    );
  }
}

class AdminInstructorDetail {
  final int id;
  final String name;
  final String instructorNumber;
  final String? avatarUrl;
  final String status;
  final String email;
  final String? phone;
  final String? department;
  final String? position;
  final DateTime? dateHired;
  final String activationCode;
  final DateTime activationCodeCreatedAt;
  final String accountStatus;
  final DateTime? activatedAt;
  final DateTime? lastLoginAt;
  final String? academicYear;
  final List<AdminAssignedSection> assignedSections;
  final List<AdminInstructorStudent> enrolledStudents;
  final int totalEnrolled;

  const AdminInstructorDetail({
    required this.id,
    required this.name,
    required this.instructorNumber,
    this.avatarUrl,
    required this.status,
    required this.email,
    this.phone,
    this.department,
    this.position,
    this.dateHired,
    required this.activationCode,
    required this.activationCodeCreatedAt,
    required this.accountStatus,
    this.activatedAt,
    this.lastLoginAt,
    this.academicYear,
    required this.assignedSections,
    required this.enrolledStudents,
    required this.totalEnrolled,
  });

  bool get isActive => status == 'active';
  bool get isActivated => accountStatus == 'activated';

  factory AdminInstructorDetail.fromJson(Map<String, dynamic> json) {
    return AdminInstructorDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      instructorNumber: json['instructorNumber'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      department: json['department'] as String?,
      position: json['position'] as String?,
      dateHired: json['dateHired'] != null ? DateTime.parse(json['dateHired'] as String) : null,
      activationCode: json['activationCode'] as String,
      activationCodeCreatedAt: DateTime.parse(json['activationCodeCreatedAt'] as String),
      accountStatus: json['accountStatus'] as String,
      activatedAt:
          json['activatedAt'] != null ? DateTime.parse(json['activatedAt'] as String) : null,
      lastLoginAt:
          json['lastLoginAt'] != null ? DateTime.parse(json['lastLoginAt'] as String) : null,
      academicYear: json['academicYear'] as String?,
      assignedSections: (json['assignedSections'] as List<dynamic>)
          .map((s) => AdminAssignedSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      enrolledStudents: (json['enrolledStudents'] as List<dynamic>)
          .map((s) => AdminInstructorStudent.fromJson(s as Map<String, dynamic>))
          .toList(),
      totalEnrolled: json['totalEnrolled'] as int,
    );
  }
}

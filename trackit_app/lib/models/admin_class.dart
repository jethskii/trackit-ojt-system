/// One row in the Class Management list -- every section school-wide,
/// not scoped to any one instructor (that's the whole point of the
/// admin view). instructorName is null until Faculty assignment (a
/// separate, not-yet-built feature) links an instructor to the section.
class AdminClassSummary {
  final int id;
  final String program;
  final String section;
  final String academicYear;
  final String? instructorName;
  final int studentCount;

  const AdminClassSummary({
    required this.id,
    required this.program,
    required this.section,
    required this.academicYear,
    this.instructorName,
    required this.studentCount,
  });

  factory AdminClassSummary.fromJson(Map<String, dynamic> json) {
    return AdminClassSummary(
      id: json['id'] as int,
      program: json['program'] as String,
      section: json['section'] as String,
      academicYear: json['academicYear'] as String,
      instructorName: json['instructorName'] as String?,
      studentCount: json['studentCount'] as int,
    );
  }
}

/// Every academic year that has real sections, plus which one is
/// "current" (the most recent, shown as Active in the picker).
class AdminAcademicYear {
  final String year;
  final int classCount;
  final bool isCurrent;

  const AdminAcademicYear({
    required this.year,
    required this.classCount,
    required this.isCurrent,
  });

  factory AdminAcademicYear.fromJson(Map<String, dynamic> json) {
    return AdminAcademicYear(
      year: json['year'] as String,
      classCount: json['classCount'] as int,
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }
}

enum AdminStudentStatus { assigned, preparing, inactive }

AdminStudentStatus _statusFromDb(String value) {
  switch (value) {
    case 'assigned':
      return AdminStudentStatus.assigned;
    case 'inactive':
      return AdminStudentStatus.inactive;
    default:
      return AdminStudentStatus.preparing;
  }
}

/// Whether the student has actually activated their own account (set a
/// password by registering with the section's activation code) --
/// separate from [AdminStudentStatus], which is about OJT progress, not
/// account access. Pending is real for imported students; every
/// self-registered student is Activated by definition.
enum AdminAccountStatus { activated, pending }

AdminAccountStatus _accountStatusFromDb(String value) {
  return value == 'activated' ? AdminAccountStatus.activated : AdminAccountStatus.pending;
}

class AdminClassStudent {
  final int id;
  final String name;
  final String email;
  final String? studentNumber;
  final String? avatarUrl;
  final String? assignedCompany;
  final AdminStudentStatus status;
  final String? contactPerson;
  final String? ojtSupervisor;
  final AdminAccountStatus accountStatus;
  final DateTime? dateActivated;

  const AdminClassStudent({
    required this.id,
    required this.name,
    required this.email,
    this.studentNumber,
    this.avatarUrl,
    this.assignedCompany,
    required this.status,
    this.contactPerson,
    this.ojtSupervisor,
    required this.accountStatus,
    this.dateActivated,
  });

  factory AdminClassStudent.fromJson(Map<String, dynamic> json) {
    return AdminClassStudent(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      studentNumber: json['studentNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      assignedCompany: json['assignedCompany'] as String?,
      status: _statusFromDb(json['status'] as String),
      contactPerson: json['contactPerson'] as String?,
      ojtSupervisor: json['ojtSupervisor'] as String?,
      accountStatus: _accountStatusFromDb(json['accountStatus'] as String),
      dateActivated: json['dateActivated'] != null
          ? DateTime.parse(json['dateActivated'] as String)
          : null,
    );
  }
}

class AdminClassDetail {
  final int id;
  final String program;
  final String? programFullName;
  final String section;
  final String academicYear;
  final String? yearLevel;
  final String? instructorName;
  final String? instructorEmail;
  final String activationCode;
  final DateTime activationCodeCreatedAt;
  final int totalStudents;
  final List<AdminClassStudent> students;

  const AdminClassDetail({
    required this.id,
    required this.program,
    this.programFullName,
    required this.section,
    required this.academicYear,
    this.yearLevel,
    this.instructorName,
    this.instructorEmail,
    required this.activationCode,
    required this.activationCodeCreatedAt,
    required this.totalStudents,
    required this.students,
  });

  factory AdminClassDetail.fromJson(Map<String, dynamic> json) {
    return AdminClassDetail(
      id: json['id'] as int,
      program: json['program'] as String,
      programFullName: json['programFullName'] as String?,
      section: json['section'] as String,
      academicYear: json['academicYear'] as String,
      yearLevel: json['yearLevel'] as String?,
      instructorName: json['instructorName'] as String?,
      instructorEmail: json['instructorEmail'] as String?,
      activationCode: json['activationCode'] as String,
      activationCodeCreatedAt: DateTime.parse(json['activationCodeCreatedAt'] as String),
      totalStudents: json['totalStudents'] as int,
      students: (json['students'] as List<dynamic>)
          .map((s) => AdminClassStudent.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Result of an Import Students upload -- how many rows became real
/// accounts, and which were skipped (with why), so the admin can fix a
/// CSV and re-upload just the problem rows instead of guessing.
class AdminImportResult {
  final int created;
  final List<AdminImportSkip> skipped;

  const AdminImportResult({required this.created, required this.skipped});

  factory AdminImportResult.fromJson(Map<String, dynamic> json) {
    return AdminImportResult(
      created: json['created'] as int,
      skipped: (json['skipped'] as List<dynamic>)
          .map((s) => AdminImportSkip.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AdminImportSkip {
  final String email;
  final String reason;

  const AdminImportSkip({required this.email, required this.reason});

  factory AdminImportSkip.fromJson(Map<String, dynamic> json) {
    return AdminImportSkip(
      email: json['email'] as String,
      reason: json['reason'] as String,
    );
  }
}

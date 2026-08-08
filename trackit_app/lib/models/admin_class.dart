/// One row in the Class Management list -- every section school-wide,
/// not scoped to any one instructor (that's the whole point of the
/// admin view).
class AdminClassSummary {
  final int id;
  final String program;
  final String section;
  final String academicYear;
  final String instructorName;
  final int studentCount;

  const AdminClassSummary({
    required this.id,
    required this.program,
    required this.section,
    required this.academicYear,
    required this.instructorName,
    required this.studentCount,
  });

  factory AdminClassSummary.fromJson(Map<String, dynamic> json) {
    return AdminClassSummary(
      id: json['id'] as int,
      program: json['program'] as String,
      section: json['section'] as String,
      academicYear: json['academicYear'] as String,
      instructorName: json['instructorName'] as String,
      studentCount: json['studentCount'] as int,
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

class AdminClassStudent {
  final int id;
  final String name;
  final String? studentNumber;
  final String? avatarUrl;
  final String? assignedCompany;
  final AdminStudentStatus status;
  final String? contactPerson;
  final String? ojtSupervisor;

  const AdminClassStudent({
    required this.id,
    required this.name,
    this.studentNumber,
    this.avatarUrl,
    this.assignedCompany,
    required this.status,
    this.contactPerson,
    this.ojtSupervisor,
  });

  factory AdminClassStudent.fromJson(Map<String, dynamic> json) {
    return AdminClassStudent(
      id: json['id'] as int,
      name: json['name'] as String,
      studentNumber: json['studentNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      assignedCompany: json['assignedCompany'] as String?,
      status: _statusFromDb(json['status'] as String),
      contactPerson: json['contactPerson'] as String?,
      ojtSupervisor: json['ojtSupervisor'] as String?,
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
  final String instructorName;
  final String instructorEmail;
  final String activationCode;
  final int totalStudents;
  final List<AdminClassStudent> students;

  const AdminClassDetail({
    required this.id,
    required this.program,
    this.programFullName,
    required this.section,
    required this.academicYear,
    this.yearLevel,
    required this.instructorName,
    required this.instructorEmail,
    required this.activationCode,
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
      instructorName: json['instructorName'] as String,
      instructorEmail: json['instructorEmail'] as String,
      activationCode: json['activationCode'] as String,
      totalStudents: json['totalStudents'] as int,
      students: (json['students'] as List<dynamic>)
          .map((s) => AdminClassStudent.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

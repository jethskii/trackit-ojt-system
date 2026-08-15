import 'admin_class.dart';

/// The Class Management Student Details panel's real data source -- the
/// same fields the reference design shows, all traced back to the
/// student's actual record (see server/routes/adminClasses.js's
/// GET /:id/students/:studentId, which reuses loadClassStudents rather
/// than recomputing status/company/contact separately).
class AdminStudentCompanyDetail {
  final String name;
  final String? industry;
  final String? address;
  final DateTime? dateDeployed;
  final String? supervisorName;
  final String? supervisorContact;

  const AdminStudentCompanyDetail({
    required this.name,
    this.industry,
    this.address,
    this.dateDeployed,
    this.supervisorName,
    this.supervisorContact,
  });

  factory AdminStudentCompanyDetail.fromJson(Map<String, dynamic> json) {
    return AdminStudentCompanyDetail(
      name: json['name'] as String,
      industry: json['industry'] as String?,
      address: json['address'] as String?,
      dateDeployed:
          json['dateDeployed'] != null ? DateTime.parse(json['dateDeployed'] as String) : null,
      supervisorName: json['supervisorName'] as String?,
      supervisorContact: json['supervisorContact'] as String?,
    );
  }
}

class AdminStudentProgressDetail {
  final double completedHours;
  final double requiredHours;
  final int daysAttended;
  final double weeklyAverageHours;

  const AdminStudentProgressDetail({
    required this.completedHours,
    required this.requiredHours,
    required this.daysAttended,
    required this.weeklyAverageHours,
  });

  double get completionPercent =>
      requiredHours > 0 ? (completedHours / requiredHours * 100).clamp(0, 100) : 0;

  /// Same pace-based projection the student's own Attendance tab already
  /// uses (attendance_service.dart's _estimateCompletion) -- there's no
  /// server-computed target date to reuse, so this mirrors that existing
  /// formula rather than inventing a different one.
  DateTime? get estimatedCompletion {
    final remainingHours = requiredHours - completedHours;
    if (remainingHours <= 0) return null;
    if (weeklyAverageHours <= 0) return null;
    final remainingWeeks = remainingHours / weeklyAverageHours;
    return DateTime.now().add(Duration(days: (remainingWeeks * 7).round()));
  }

  factory AdminStudentProgressDetail.fromJson(Map<String, dynamic> json) {
    return AdminStudentProgressDetail(
      completedHours: (json['completedHours'] as num).toDouble(),
      requiredHours: (json['requiredHours'] as num).toDouble(),
      daysAttended: json['daysAttended'] as int,
      weeklyAverageHours: (json['weeklyAverageHours'] as num).toDouble(),
    );
  }
}

class AdminStudentDetail {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? studentNumber;
  final AdminAccountStatus accountStatus;
  final DateTime? dateActivated;
  final AdminStudentStatus ojtStatus;
  final String? program;
  final String? section;
  final String? phone;
  final String email;
  final String? address;
  final String? guardianContact;
  final AdminStudentCompanyDetail? company;
  final AdminStudentProgressDetail progress;

  const AdminStudentDetail({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.studentNumber,
    required this.accountStatus,
    this.dateActivated,
    required this.ojtStatus,
    this.program,
    this.section,
    this.phone,
    required this.email,
    this.address,
    this.guardianContact,
    this.company,
    required this.progress,
  });

  factory AdminStudentDetail.fromJson(Map<String, dynamic> json) {
    return AdminStudentDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      studentNumber: json['studentNumber'] as String?,
      accountStatus:
          json['accountStatus'] == 'activated' ? AdminAccountStatus.activated : AdminAccountStatus.pending,
      dateActivated:
          json['dateActivated'] != null ? DateTime.parse(json['dateActivated'] as String) : null,
      ojtStatus: _ojtStatusFromDb(json['ojtStatus'] as String),
      program: json['program'] as String?,
      section: json['section'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String,
      address: json['address'] as String?,
      guardianContact: json['guardianContact'] as String?,
      company: json['company'] != null
          ? AdminStudentCompanyDetail.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      progress: AdminStudentProgressDetail.fromJson(json['progress'] as Map<String, dynamic>),
    );
  }
}

AdminStudentStatus _ojtStatusFromDb(String value) {
  switch (value) {
    case 'assigned':
      return AdminStudentStatus.assigned;
    case 'inactive':
      return AdminStudentStatus.inactive;
    default:
      return AdminStudentStatus.preparing;
  }
}

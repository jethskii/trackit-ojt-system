/// Where a student currently sits in the OJT pipeline.
///
/// This drives the "Today's Summary" tiles on the teacher dashboard, so a
/// student's stage should always reflect their real progress: everyone
/// assigned to a teacher counts toward [assignedTotal], while
/// [readyForDeployment], [active] and [completed] are mutually exclusive
/// snapshots of where they are right now.
enum StudentOjtStage {
  pending,
  readyForDeployment,
  active,
  completed,
}

class Student {
  final String id;
  final String name;
  final String program;
  final String section;
  final String teacherId;
  final StudentOjtStage stage;
  final String? companyName;
  final List<String> pendingRequirements;
  final bool needsAttendanceCorrection;
  final bool hasCompanyChangeRequest;

  const Student({
    required this.id,
    required this.name,
    required this.program,
    required this.section,
    required this.teacherId,
    required this.stage,
    this.companyName,
    this.pendingRequirements = const [],
    this.needsAttendanceCorrection = false,
    this.hasCompanyChangeRequest = false,
  });

  bool get hasPendingRequirements => pendingRequirements.isNotEmpty;
}

import '../data/mock_data.dart';
import '../models/announcement.dart';
import '../models/notification_item.dart';
import '../models/student.dart';
import '../models/teacher.dart';

/// Everything the teacher Home dashboard needs to render, computed from
/// the teacher's actual assigned students rather than fixed numbers.
class HomeDashboardData {
  final Teacher teacher;
  final int assignedStudents;
  final int activeStudents;
  final int readyForDeployment;
  final int completedStudents;
  final int requirementsToReview;
  final int attendanceCorrections;
  final int companyChangeRequests;
  final List<Announcement> announcements;
  final List<NotificationItem> notifications;

  const HomeDashboardData({
    required this.teacher,
    required this.assignedStudents,
    required this.activeStudents,
    required this.readyForDeployment,
    required this.completedStudents,
    required this.requirementsToReview,
    required this.attendanceCorrections,
    required this.companyChangeRequests,
    required this.announcements,
    required this.notifications,
  });
}

/// Reads from [MockData] today; swap the body for real API calls once the
/// backend is wired up without changing what the dashboard screen expects.
class DashboardRepository {
  DashboardRepository._();

  static final DashboardRepository instance = DashboardRepository._();

  HomeDashboardData getHomeDashboardData(String teacherId) {
    final teacher = MockData.teachers.firstWhere((t) => t.id == teacherId);
    final students = MockData.students.where((s) => s.teacherId == teacherId).toList();

    return HomeDashboardData(
      teacher: teacher,
      assignedStudents: students.length,
      activeStudents: students.where((s) => s.stage == StudentOjtStage.active).length,
      readyForDeployment:
          students.where((s) => s.stage == StudentOjtStage.readyForDeployment).length,
      completedStudents: students.where((s) => s.stage == StudentOjtStage.completed).length,
      requirementsToReview: students.where((s) => s.hasPendingRequirements).length,
      attendanceCorrections: students.where((s) => s.needsAttendanceCorrection).length,
      companyChangeRequests: students.where((s) => s.hasCompanyChangeRequest).length,
      announcements: MockData.announcements,
      notifications: MockData.notifications,
    );
  }
}

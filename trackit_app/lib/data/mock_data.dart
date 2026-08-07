import '../models/announcement.dart';
import '../models/notification_item.dart';
import '../models/student.dart';
import '../models/teacher.dart';

/// Sample data standing in for the future TrackIT backend.
///
/// The dashboard never hardcodes its counts: it always derives them from
/// this student list, so swapping this file for a real API response later
/// (same [Student] shape) is a drop-in replacement.
class MockData {
  MockData._();

  static const List<Teacher> teachers = [
    Teacher(
      id: 't1',
      name: 'Althea',
      honorific: "Ma'am",
      program: 'BSIT',
      sections: ['4E', '4F'],
    ),
  ];

  static final List<Student> students = _buildStudents();

  static List<Student> _buildStudents() {
    const firstNames = [
      'Juan', 'Maria', 'Jose', 'Ana', 'Pedro',
      'Liza', 'Mark', 'Grace', 'Paolo', 'Erika',
    ];
    const lastNames = ['Santos', 'Dela Cruz', 'Reyes', 'Bautista'];
    const companies = ['Accenture', 'Globe Telecom', 'IBM Solutions', 'Smart Comms'];

    const requirementsByIndex = {
      15: ['Endorsement Letter'],
      16: ['Medical Certificate', 'Insurance Form'],
      28: ['Resume'],
      29: ['Parent Consent Form'],
      30: ['Medical Certificate'],
      31: ['Endorsement Letter', 'Resume'],
    };
    const attendanceCorrectionIndices = {18, 22, 25};
    const companyChangeIndices = {20};

    return List.generate(40, (i) {
      final stage = i < 5
          ? StudentOjtStage.completed
          : i < 13
              ? StudentOjtStage.readyForDeployment
              : i < 28
                  ? StudentOjtStage.active
                  : StudentOjtStage.pending;

      final isDeployed = stage == StudentOjtStage.active || stage == StudentOjtStage.completed;

      return Student(
        id: 's${i + 1}',
        name: '${firstNames[i % firstNames.length]} ${lastNames[i ~/ firstNames.length]}',
        program: 'BSIT',
        section: i.isEven ? '4E' : '4F',
        teacherId: 't1',
        stage: stage,
        companyName: isDeployed ? companies[i % companies.length] : null,
        pendingRequirements: requirementsByIndex[i] ?? const [],
        needsAttendanceCorrection: attendanceCorrectionIndices.contains(i),
        hasCompanyChangeRequest: companyChangeIndices.contains(i),
      );
    });
  }

  static final List<Announcement> announcements = [
    Announcement(
      id: 'a1',
      title: 'OJT Endorsement Deadline Moved Up',
      body: 'Submit endorsement letters for Batch 2026 by August 15.',
      postedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  static final List<NotificationItem> notifications = [
    NotificationItem(
      id: 'n1',
      title: 'Attendance correction requested',
      message: 'Mark Reyes flagged a missed time-in on Aug 6.',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];
}

import 'package:flutter/material.dart';
import '../../models/attendance.dart';
import '../../models/ojt_progress.dart';
import '../../models/student.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/coming_soon_view.dart';
import 'student_attendance_view.dart';
import 'student_home_view.dart';

class StudentShell extends StatefulWidget {
  final Student student;
  final OjtProgress progress;
  final List<String> announcements;
  final TodayAttendance todayAttendance;
  final List<AttendanceHistoryEntry> attendanceHistory;

  const StudentShell({
    super.key,
    required this.student,
    required this.progress,
    required this.todayAttendance,
    this.announcements = const [],
    this.attendanceHistory = const [],
  });

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _navIndex = 0;

  static const _navItems = [
    AppBottomNavItem(icon: Icons.home, label: 'Home'),
    AppBottomNavItem(icon: Icons.event_available, label: 'Attendance'),
    AppBottomNavItem(icon: Icons.description, label: 'Document'),
    AppBottomNavItem(icon: Icons.notifications, label: 'Notification'),
    AppBottomNavItem(icon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentHomeView(
        student: widget.student,
        progress: widget.progress,
        announcements: widget.announcements,
      ),
      StudentAttendanceView(
        progress: widget.progress,
        initialAttendance: widget.todayAttendance,
        history: widget.attendanceHistory,
      ),
      const ComingSoonView(
        title: 'Document',
        subtitle: 'Requirements & Weekly Reports',
      ),
      const ComingSoonView(
        title: 'Notification',
        subtitle: 'Announcements & Alerts',
      ),
      const ComingSoonView(title: 'Profile', subtitle: 'Account & Settings'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _navIndex, children: pages),
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }
}

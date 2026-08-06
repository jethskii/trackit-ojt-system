import 'package:flutter/material.dart';
import '../../models/ojt_progress.dart';
import '../../models/student.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/student/announcements_section.dart';
import '../../widgets/student/ojt_progress_card.dart';
import '../../widgets/student/student_home_header.dart';
import '../../widgets/student/student_profile_card.dart';

class StudentDashboardScreen extends StatefulWidget {
  final Student student;
  final OjtProgress progress;
  final List<String> announcements;

  const StudentDashboardScreen({
    super.key,
    required this.student,
    required this.progress,
    this.announcements = const [],
  });

  @override
  State<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StudentHomeHeader(
                title: 'Home',
                subtitle: 'Personal Dashboard',
              ),
              Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StudentProfileCard(student: widget.student),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: OjtProgressCard(progress: widget.progress),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: AnnouncementsSection(
                  announcements: widget.announcements,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }
}

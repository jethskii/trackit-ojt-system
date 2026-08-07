import 'package:flutter/material.dart';
import '../../models/teacher_dashboard.dart';
import '../../services/teacher_dashboard_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_bottom_nav.dart';
import 'teacher_home_dashboard_screen.dart';
import 'teacher_placeholder_screen.dart';
import 'teacher_profile_screen.dart';

class TeacherShell extends StatefulWidget {
  final TeacherDashboardService dashboardService;
  final TeacherDashboard initialDashboard;
  final VoidCallback onLoggedOut;

  const TeacherShell({
    super.key,
    required this.dashboardService,
    required this.initialDashboard,
    required this.onLoggedOut,
  });

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _navIndex = 0;
  late TeacherDashboard _dashboard;

  @override
  void initState() {
    super.initState();
    _dashboard = widget.initialDashboard;
  }

  Future<void> _refreshDashboard() async {
    final dashboard = await widget.dashboardService.getDashboard();
    if (!mounted) return;
    setState(() => _dashboard = dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TeacherHomeDashboardScreen(
        dashboard: _dashboard,
        onOpenNotifications: () => setState(() => _navIndex = 3),
        onRefresh: _refreshDashboard,
      ),
      const TeacherPlaceholderScreen(
        title: 'Students',
        icon: Icons.groups_outlined,
      ),
      const TeacherPlaceholderScreen(
        title: 'Document',
        icon: Icons.description_outlined,
      ),
      const TeacherPlaceholderScreen(
        title: 'Notification',
        icon: Icons.notifications_none,
      ),
      TeacherProfileScreen(
        instructorName: _dashboard.instructorName,
        onLoggedOut: widget.onLoggedOut,
      ),
    ];

    final navItems = [
      const AppBottomNavItem(icon: Icons.home, label: 'Home'),
      const AppBottomNavItem(icon: Icons.groups, label: 'Students'),
      const AppBottomNavItem(icon: Icons.description, label: 'Document'),
      const AppBottomNavItem(icon: Icons.notifications, label: 'Notification'),
      const AppBottomNavItem(icon: Icons.person, label: 'Profile'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _navIndex, children: pages),
      bottomNavigationBar: AppBottomNav(
        items: navItems,
        currentIndex: _navIndex,
        onTap: (index) => setState(() => _navIndex = index),
      ),
    );
  }
}

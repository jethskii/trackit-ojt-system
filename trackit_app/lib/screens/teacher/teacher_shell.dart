import 'package:flutter/material.dart';
import '../../models/teacher_dashboard.dart';
import '../../services/api_client.dart';
import '../../services/teacher_announcements_service.dart';
import '../../services/teacher_classes_service.dart';
import '../../services/teacher_dashboard_service.dart';
import '../../services/teacher_notifications_service.dart';
import '../../services/teacher_students_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_bottom_nav.dart';
import 'teacher_home_dashboard_screen.dart';
import 'teacher_notifications_tab_navigator.dart';
import 'teacher_placeholder_screen.dart';
import 'teacher_profile_screen.dart';
import 'teacher_students_tab_navigator.dart';

class TeacherShell extends StatefulWidget {
  final ApiClient client;
  final TeacherDashboardService dashboardService;
  final TeacherDashboard initialDashboard;
  final VoidCallback onLoggedOut;

  const TeacherShell({
    super.key,
    required this.client,
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
  late final TeacherClassesService _classesService = HttpTeacherClassesService(
    widget.client,
  );
  late final TeacherStudentsService _studentsService = HttpTeacherStudentsService(
    widget.client,
  );
  late final TeacherNotificationsService _notificationsService =
      HttpTeacherNotificationsService(widget.client);
  late final TeacherAnnouncementsService _announcementsService =
      HttpTeacherAnnouncementsService(widget.client);

  @override
  void initState() {
    super.initState();
    _dashboard = widget.initialDashboard;
    // Loaded once here (rather than only inside the Notification tab) so
    // the Home Dashboard's preview and the bottom-nav badge have data
    // even if that tab is never opened directly.
    _notificationsService.load();
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
        notificationsService: _notificationsService,
        announcementsService: _announcementsService,
        onOpenNotifications: () => setState(() => _navIndex = 3),
        onRefresh: _refreshDashboard,
      ),
      TeacherStudentsTabNavigator(
        classesService: _classesService,
        studentsService: _studentsService,
      ),
      const TeacherPlaceholderScreen(
        title: 'Document',
        icon: Icons.description_outlined,
      ),
      TeacherNotificationsTabNavigator(
        notificationsService: _notificationsService,
        announcementsService: _announcementsService,
        classesService: _classesService,
      ),
      TeacherProfileScreen(
        instructorName: _dashboard.instructorName,
        onLoggedOut: widget.onLoggedOut,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _navIndex, children: pages),
      bottomNavigationBar: ListenableBuilder(
        listenable: _notificationsService,
        builder: (context, _) {
          final navItems = [
            const AppBottomNavItem(icon: Icons.home, label: 'Home'),
            const AppBottomNavItem(icon: Icons.groups, label: 'Students'),
            const AppBottomNavItem(icon: Icons.description, label: 'Document'),
            AppBottomNavItem(
              icon: Icons.notifications,
              label: 'Notification',
              badgeCount: _notificationsService.unreadCount,
            ),
            const AppBottomNavItem(icon: Icons.person, label: 'Profile'),
          ];
          return AppBottomNav(
            items: navItems,
            currentIndex: _navIndex,
            onTap: (index) => setState(() => _navIndex = index),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../widgets/trackit_bottom_nav_bar.dart';
import 'placeholder_screen.dart';
import 'teacher_home_dashboard_screen.dart';

/// Scaffold shared by the five teacher tabs, switching between them via the
/// bottom navigation bar while keeping each tab's state alive.
class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});

  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int _currentIndex = 0;

  static const _screens = [
    TeacherHomeDashboardScreen(),
    PlaceholderScreen(title: 'Students', icon: Icons.groups_rounded),
    PlaceholderScreen(title: 'Document', icon: Icons.description_rounded),
    PlaceholderScreen(title: 'Notification', icon: Icons.campaign_rounded),
    PlaceholderScreen(title: 'Profile', icon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: TrackitBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/admin_classes_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import 'admin_classes_tab_navigator.dart';
import 'admin_placeholder_screen.dart';

class _AdminSection {
  final String label;
  final IconData icon;

  const _AdminSection(this.label, this.icon);
}

const _sections = [
  _AdminSection('Overview', Icons.dashboard_outlined),
  _AdminSection('Class Management', Icons.class_outlined),
  _AdminSection('HTE Directory', Icons.apartment_outlined),
  _AdminSection('Archive', Icons.archive_outlined),
  _AdminSection('Announcements', Icons.campaign_outlined),
  _AdminSection('Profile', Icons.account_circle_outlined),
];

/// Admin's shell is a left sidebar (web-first, per the mockup) rather than
/// the bottom nav every other role uses -- Admin is explicitly a web
/// surface, so this is a deliberate, one-off departure from the shared
/// AppBottomNav pattern, not an inconsistency.
class AdminShell extends StatefulWidget {
  final ApiClient client;
  final VoidCallback onLoggedOut;

  const AdminShell({super.key, required this.client, required this.onLoggedOut});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 1; // Class Management is the only built-out section so far.
  late final AdminClassesService _classesService = HttpAdminClassesService(
    widget.client,
  );

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onLoggedOut();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const AdminPlaceholderScreen(title: 'Overview', icon: Icons.dashboard_outlined),
      AdminClassesTabNavigator(classesService: _classesService),
      const AdminPlaceholderScreen(
        title: 'HTE Directory',
        icon: Icons.apartment_outlined,
      ),
      const AdminPlaceholderScreen(title: 'Archive', icon: Icons.archive_outlined),
      const AdminPlaceholderScreen(
        title: 'Announcements',
        icon: Icons.campaign_outlined,
      ),
      const AdminPlaceholderScreen(
        title: 'Profile',
        icon: Icons.account_circle_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            width: 240,
            color: AppColors.primaryMaroon,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'TRACKIT ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < _sections.length; i++)
                    _SidebarItem(
                      icon: _sections[i].icon,
                      label: _sections[i].label,
                      selected: _index == i,
                      onTap: () => setState(() => _index = i),
                    ),
                  const Spacer(),
                  const Divider(color: Colors.white24, height: 1),
                  _SidebarItem(
                    icon: Icons.logout,
                    label: 'Log Out',
                    selected: false,
                    onTap: _confirmLogout,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              left: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: IndexedStack(index: _index, children: pages),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColors.accentOrange : Colors.white70,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

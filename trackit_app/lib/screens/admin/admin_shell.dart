import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import 'admin_announcements_screen.dart';
import 'admin_class_management_screen.dart';
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
  _AdminSection('Announcements', Icons.campaign_outlined),
  _AdminSection('Archive', Icons.archive_outlined),
  _AdminSection('Profile', Icons.account_circle_outlined),
];

// Below this width there's no room for a 250px-wide sidebar sitting next
// to real content -- the sidebar becomes a Drawer instead.
const _wideBreakpoint = 900.0;

/// Admin's shell is a left sidebar (web-first, per the mockup) rather than
/// the bottom nav every other role uses -- Admin is explicitly a web
/// surface, so this is a deliberate, one-off departure from the shared
/// AppBottomNav pattern, not an inconsistency. On a narrow viewport
/// (phone, or a resized browser window) it falls back to a Drawer + AppBar
/// so the sidebar doesn't just overflow the screen.
class AdminShell extends StatefulWidget {
  final ApiClient client;
  final String adminName;
  final String adminEmail;
  final VoidCallback onLoggedOut;

  const AdminShell({
    super.key,
    required this.client,
    required this.adminName,
    required this.adminEmail,
    required this.onLoggedOut,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 1; // Class Management is the only built-out section so far.

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

  Widget _buildSidebarContent({required bool closeDrawerOnTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Row(
            children: [
              _LogoMark(),
              SizedBox(width: 10),
              Text(
                'TrackIT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.adminName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Administrator',
                      style: TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < _sections.length; i++)
          _SidebarItem(
            icon: _sections[i].icon,
            label: _sections[i].label,
            selected: _index == i,
            onTap: () {
              setState(() => _index = i);
              if (closeDrawerOnTap) Navigator.of(context).pop();
            },
          ),
        const Spacer(),
        const Divider(color: Colors.white24, height: 1),
        _SidebarItem(
          icon: Icons.logout,
          label: 'Log Out',
          selected: false,
          onTap: () {
            if (closeDrawerOnTap) Navigator.of(context).pop();
            _confirmLogout();
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const AdminPlaceholderScreen(title: 'Overview', icon: Icons.dashboard_outlined),
      AdminClassManagementScreen(client: widget.client),
      const AdminPlaceholderScreen(
        title: 'HTE Directory',
        icon: Icons.apartment_outlined,
      ),
      AdminAnnouncementsScreen(client: widget.client),
      const AdminPlaceholderScreen(title: 'Archive', icon: Icons.archive_outlined),
      const AdminPlaceholderScreen(
        title: 'Profile',
        icon: Icons.account_circle_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        if (isWide) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                Container(
                  width: 250,
                  color: AppColors.primaryMaroon,
                  child: SafeArea(
                    child: _buildSidebarContent(closeDrawerOnTap: false),
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

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: Colors.white,
            title: Text(_sections[_index].label),
          ),
          drawer: Drawer(
            backgroundColor: AppColors.primaryMaroon,
            child: SafeArea(child: _buildSidebarContent(closeDrawerOnTap: true)),
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: IndexedStack(index: _index, children: pages),
          ),
        );
      },
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
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
        color: selected ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
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
                  color: selected ? Colors.white : Colors.white70,
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

import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/settings_section_header.dart';
import '../../../widgets/common/settings_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _documentUpdates = true;
  bool _attendanceReminders = true;
  bool _reportUpdates = true;
  bool _systemAnnouncements = true;
  bool _profilePublic = false;

  void _stub(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Deleting your account requires admin approval and cannot be '
          'undone once processed. Are you sure you want to request this?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _stub('Account deletion requests');
            },
            child: const Text(
              'Request Deletion',
              style: TextStyle(color: AppColors.statRedIcon),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackNavHeader(subtitle: 'Settings'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SettingsSectionHeader(title: 'Account'),
                  _Group(
                    children: [
                      SettingsTile(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profile',
                        onTap: () => _stub('Edit Profile'),
                      ),
                      SettingsTile(
                        icon: Icons.photo_camera_outlined,
                        title: 'Change Profile Picture',
                        onTap: () => _stub('Profile picture upload'),
                      ),
                      SettingsTile(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        onTap: () => _stub('Change Password'),
                      ),
                      SettingsTile(
                        icon: Icons.alternate_email,
                        title: 'Change Email',
                        onTap: () => _stub('Change Email'),
                      ),
                      SettingsTile(
                        icon: Icons.phone_outlined,
                        title: 'Change Mobile Number',
                        onTap: () => _stub('Change Mobile Number'),
                      ),
                    ],
                  ),
                  const SettingsSectionHeader(title: 'Security'),
                  _Group(
                    children: [
                      SettingsTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Two-Factor Authentication',
                        subtitle: 'Future-ready -- not yet available',
                        onTap: () => _stub('Two-Factor Authentication'),
                      ),
                      SettingsTile(
                        icon: Icons.devices_outlined,
                        title: 'Active Sessions',
                        onTap: () => _stub('Active Sessions'),
                      ),
                      SettingsTile(
                        icon: Icons.history,
                        title: 'Login History',
                        onTap: () => _stub('Login History'),
                      ),
                      SettingsTile(
                        icon: Icons.logout,
                        title: 'Logout Other Devices',
                        onTap: () => _stub('Logout Other Devices'),
                      ),
                    ],
                  ),
                  const SettingsSectionHeader(title: 'Notifications'),
                  _Group(
                    children: [
                      SettingsTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'Push Notifications',
                        trailing: Switch(
                          value: _pushEnabled,
                          activeThumbColor: AppColors.primaryMaroon,
                          onChanged: (v) => setState(() => _pushEnabled = v),
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.mail_outline,
                        title: 'Email Notifications',
                        trailing: Switch(
                          value: _emailEnabled,
                          activeThumbColor: AppColors.primaryMaroon,
                          onChanged: (v) => setState(() => _emailEnabled = v),
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.description_outlined,
                        title: 'Document Updates',
                        trailing: Switch(
                          value: _documentUpdates,
                          activeThumbColor: AppColors.primaryMaroon,
                          onChanged: (v) =>
                              setState(() => _documentUpdates = v),
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.event_available_outlined,
                        title: 'Attendance Reminders',
                        trailing: Switch(
                          value: _attendanceReminders,
                          activeThumbColor: AppColors.primaryMaroon,
                          onChanged: (v) =>
                              setState(() => _attendanceReminders = v),
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.assignment_outlined,
                        title: 'Report Updates',
                        trailing: Switch(
                          value: _reportUpdates,
                          activeThumbColor: AppColors.primaryMaroon,
                          onChanged: (v) => setState(() => _reportUpdates = v),
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.campaign_outlined,
                        title: 'System Announcements',
                        trailing: Switch(
                          value: _systemAnnouncements,
                          activeThumbColor: AppColors.primaryMaroon,
                          onChanged: (v) =>
                              setState(() => _systemAnnouncements = v),
                        ),
                      ),
                    ],
                  ),
                  const SettingsSectionHeader(title: 'Appearance'),
                  _Group(
                    children: [
                      SettingsTile(
                        icon: Icons.light_mode_outlined,
                        title: 'Light Mode',
                        subtitle: 'Currently active',
                        trailing: const Icon(
                          Icons.check_circle,
                          color: AppColors.successGreenText,
                          size: 20,
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark Mode',
                        subtitle: 'Future-ready -- not yet available',
                        trailing: Switch(
                          value: false,
                          onChanged: null,
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.format_size,
                        title: 'Font Size',
                        subtitle: 'Medium',
                        onTap: () => _stub('Font Size selection'),
                      ),
                      SettingsTile(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        subtitle: 'English',
                        onTap: () => _stub('Language selection'),
                      ),
                    ],
                  ),
                  const SettingsSectionHeader(title: 'Privacy'),
                  _Group(
                    children: [
                      SettingsTile(
                        icon: Icons.visibility_outlined,
                        title: 'Profile Visibility',
                        trailing: Switch(
                          value: _profilePublic,
                          activeThumbColor: AppColors.primaryMaroon,
                          onChanged: (v) => setState(() => _profilePublic = v),
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.fact_check_outlined,
                        title: 'Data Privacy Consent',
                        onTap: () => _stub('Data Privacy Consent'),
                      ),
                      SettingsTile(
                        icon: Icons.download_outlined,
                        title: 'Download My Data',
                        onTap: () => _stub('Download My Data'),
                      ),
                      SettingsTile(
                        icon: Icons.timeline_outlined,
                        title: 'Account Activity',
                        onTap: () => _stub('Account Activity'),
                      ),
                    ],
                  ),
                  const SettingsSectionHeader(title: 'Application'),
                  _Group(
                    children: [
                      const SettingsTile(
                        icon: Icons.info_outline,
                        title: 'App Version',
                        trailing: Text(
                          '0.1.0',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      SettingsTile(
                        icon: Icons.system_update_outlined,
                        title: 'Check for Updates',
                        onTap: () => _stub('Check for Updates'),
                      ),
                      SettingsTile(
                        icon: Icons.cleaning_services_outlined,
                        title: 'Clear Cache',
                        onTap: () => _stub('Clear Cache'),
                      ),
                      SettingsTile(
                        icon: Icons.storage_outlined,
                        title: 'Storage Usage',
                        onTap: () => _stub('Storage Usage'),
                      ),
                    ],
                  ),
                  const SettingsSectionHeader(title: 'Support'),
                  _Group(
                    children: [
                      SettingsTile(
                        icon: Icons.help_outline,
                        title: 'Help Center',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      SettingsTile(
                        icon: Icons.feedback_outlined,
                        title: 'Send Feedback',
                        onTap: () => _stub('Send Feedback'),
                      ),
                      SettingsTile(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Contact Administrator',
                        onTap: () => _stub('Contact Administrator'),
                      ),
                      SettingsTile(
                        icon: Icons.bug_report_outlined,
                        title: 'Report Bug',
                        onTap: () => _stub('Report Bug'),
                      ),
                    ],
                  ),
                  const SettingsSectionHeader(title: 'Account Actions'),
                  _Group(
                    children: [
                      SettingsTile(
                        icon: Icons.logout,
                        title: 'Logout',
                        iconColor: AppColors.statRedIcon,
                        titleColor: AppColors.statRedIcon,
                        onTap: () => _stub('Logout'),
                      ),
                      SettingsTile(
                        icon: Icons.delete_outline,
                        title: 'Delete Account',
                        subtitle: 'Admin approval required',
                        iconColor: AppColors.statRedIcon,
                        titleColor: AppColors.statRedIcon,
                        onTap: _confirmDeleteAccount,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../models/student_profile.dart';
import '../../../services/student_profile_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/app_header.dart';
import '../../../widgets/common/settings_tile.dart';
import '../../../widgets/student/profile/profile_contact_row.dart';

class ProfileScreen extends StatefulWidget {
  final StudentProfileService service;
  final VoidCallback onOpenHelpCenter;
  final VoidCallback onOpenSettings;

  const ProfileScreen({
    super.key,
    required this.service,
    required this.onOpenHelpCenter,
    required this.onOpenSettings,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StudentProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await widget.service.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  void _openAvatarPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Change Profile Picture',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primaryMaroon,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.primaryMaroon,
              ),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.of(context).pop(),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Text(
                'Photo upload needs camera/gallery access and file storage, '
                'which aren\'t wired up yet -- coming once the backend '
                'supports it.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDetail(String name, String role, String email, String phone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role, style: const TextStyle(color: AppColors.accentOrange)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16, color: AppColors.primaryMaroon),
                const SizedBox(width: 8),
                Expanded(child: Text(email)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: AppColors.primaryMaroon),
                const SizedBox(width: 8),
                Expanded(child: Text(phone)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Logout will be enabled once the login/auth module is built.',
                  ),
                ),
              );
            },
            child: const Text('Log Out'),
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
      child: _loading || _profile == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryMaroon),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppHeader(title: 'Profile', subtitle: 'Personal Dashboard'),
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ProfileCard(
                        profile: _profile!,
                        onEditAvatar: _openAvatarPicker,
                        onTapAdviser: () => _showContactDetail(
                          _profile!.adviser.name,
                          _profile!.adviser.role,
                          _profile!.adviser.email,
                          _profile!.adviser.phone,
                        ),
                        onTapCompany: () => _showContactDetail(
                          _profile!.company.name,
                          'Assigned OJT Company',
                          _profile!.company.email,
                          _profile!.company.phone,
                        ),
                        onTapSupervisor: () => _showContactDetail(
                          _profile!.supervisor.name,
                          _profile!.supervisor.role,
                          _profile!.supervisor.email,
                          _profile!.supervisor.phone,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SettingsTile(
                            icon: Icons.help_outline,
                            title: 'Help Center',
                            subtitle: 'FAQs, Guides & Support',
                            onTap: widget.onOpenHelpCenter,
                          ),
                          const Divider(height: 1),
                          SettingsTile(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            subtitle: 'Account, Privacy & Preferences',
                            onTap: widget.onOpenSettings,
                          ),
                          const Divider(height: 1),
                          SettingsTile(
                            icon: Icons.logout,
                            title: 'Log Out',
                            subtitle: 'Sign out from your account',
                            iconColor: AppColors.statRedIcon,
                            titleColor: AppColors.statRedIcon,
                            onTap: _confirmLogout,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final StudentProfile profile;
  final VoidCallback onEditAvatar;
  final VoidCallback onTapAdviser;
  final VoidCallback onTapCompany;
  final VoidCallback onTapSupervisor;

  const _ProfileCard({
    required this.profile,
    required this.onEditAvatar,
    required this.onTapAdviser,
    required this.onTapCompany,
    required this.onTapSupervisor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.background,
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? Text(
                        profile.fullName.isNotEmpty
                            ? profile.fullName.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryMaroon,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: InkWell(
                  onTap: onEditAvatar,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMaroon,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            profile.course,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accentOrange,
            ),
          ),
          Text(
            '${profile.yearLevel} - ${profile.section}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          ProfileContactRow(
            name: profile.adviser.name,
            subtitle: profile.adviser.role,
            onTap: onTapAdviser,
          ),
          const Divider(height: 1),
          ProfileContactRow(
            name: profile.company.name,
            subtitle: 'Assigned OJT Company',
            onTap: onTapCompany,
          ),
          const Divider(height: 1),
          ProfileContactRow(
            name: profile.supervisor.name,
            subtitle: profile.supervisor.role,
            onTap: onTapSupervisor,
          ),
        ],
      ),
    );
  }
}

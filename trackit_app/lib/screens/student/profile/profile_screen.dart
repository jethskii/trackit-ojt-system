import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/company_details.dart';
import '../../../models/student_profile.dart';
import '../../../services/api_client.dart';
import '../../../services/student_profile_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/app_header.dart';
import '../../../widgets/common/settings_tile.dart';
import '../../../widgets/common/shimmer_box.dart';
import '../../../widgets/student/profile/profile_contact_row.dart';

class ProfileScreen extends StatefulWidget {
  final StudentProfileService service;
  final ValueChanged<StudentProfile> onProfileUpdated;
  final VoidCallback onOpenHelpCenter;
  final VoidCallback onOpenSettings;
  final Future<void> Function() onOpenEditProfile;
  final VoidCallback onOpenLoginHistory;
  final VoidCallback onLoggedOut;

  const ProfileScreen({
    super.key,
    required this.service,
    required this.onProfileUpdated,
    required this.onOpenHelpCenter,
    required this.onOpenSettings,
    required this.onOpenEditProfile,
    required this.onOpenLoginHistory,
    required this.onLoggedOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StudentProfile? _profile;
  bool _loading = true;
  bool _uploadingAvatar = false;

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

  // Edit Profile is a separate route on the same nested Navigator, not a
  // dialog this screen owns -- popping back to this (already-mounted)
  // screen doesn't rebuild it on its own, so without this the name/photo
  // shown here would stay stale until the tab was left and reopened.
  Future<void> _openEditProfile() async {
    await widget.onOpenEditProfile();
    if (mounted) await _load();
  }

  String _inferContentType(XFile file) {
    if (file.mimeType != null) return file.mimeType!;
    final ext = file.name.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    Navigator.of(context).pop(); // close the picker sheet
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e',
          ),
          backgroundColor: AppColors.statRedIcon,
        ),
      );
      return;
    }
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final updated = await widget.service.uploadAvatar(
        bytes: bytes,
        fileName: picked.name,
        contentType: _inferContentType(picked),
      );
      if (!mounted) return;
      setState(() => _profile = updated);
      widget.onProfileUpdated(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated.'),
          backgroundColor: AppColors.successGreenText,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.statRedIcon),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reach the server. Is it running?'),
          backgroundColor: AppColors.statRedIcon,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
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
              onTap: () => _pickAndUploadAvatar(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.primaryMaroon,
              ),
              title: const Text('Take a Photo'),
              onTap: () => _pickAndUploadAvatar(ImageSource.camera),
            ),
            const SizedBox(height: 8),
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

  void _showCompanyDetail(CompanyDetails company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(company.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              company.industry,
              style: const TextStyle(color: AppColors.accentOrange),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primaryMaroon),
                const SizedBox(width: 8),
                Expanded(child: Text(company.address)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.primaryMaroon),
                const SizedBox(width: 8),
                Expanded(child: Text(company.supervisorName)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: AppColors.primaryMaroon),
                const SizedBox(width: 8),
                Expanded(child: Text(company.contactNumber)),
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
              widget.onLoggedOut();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: _loading || _profile == null
          ? const _ProfileSkeleton()
          : RefreshIndicator(
              color: AppColors.primaryMaroon,
              onRefresh: _refresh,
              child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                        uploadingAvatar: _uploadingAvatar,
                        onEditAvatar: _openAvatarPicker,
                        onTapAdviser: _profile!.adviser == null
                            ? null
                            : () => _showContactDetail(
                                _profile!.adviser!.name,
                                _profile!.adviser!.role,
                                _profile!.adviser!.email,
                                _profile!.adviser!.phone,
                              ),
                        onTapCompany: _profile!.company == null
                            ? null
                            : () => _showCompanyDetail(_profile!.company!),
                        onTapSupervisor: _profile!.supervisor == null
                            ? null
                            : () => _showContactDetail(
                                _profile!.supervisor!.name,
                                _profile!.supervisor!.role,
                                _profile!.supervisor!.email,
                                _profile!.supervisor!.phone,
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
                            icon: Icons.edit_outlined,
                            title: 'Edit Profile',
                            subtitle: 'Name, photo & contact info',
                            onTap: _openEditProfile,
                          ),
                          const Divider(height: 1),
                          SettingsTile(
                            icon: Icons.history,
                            title: 'Login History',
                            subtitle: 'Your account sign-in activity',
                            onTap: widget.onOpenLoginHistory,
                          ),
                          const Divider(height: 1),
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
            ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppHeader(title: 'Profile', subtitle: 'Personal Dashboard'),
        Transform.translate(
          offset: const Offset(0, -30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShimmerBox(
                        width: 52,
                        height: 52,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ShimmerBox(height: 16),
                            const SizedBox(height: 8),
                            ShimmerBox(
                              height: 12,
                              width:
                                  MediaQuery.sizeOf(context).width * 0.3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const ShimmerBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final StudentProfile profile;
  final bool uploadingAvatar;
  final VoidCallback onEditAvatar;
  final VoidCallback? onTapAdviser;
  final VoidCallback? onTapCompany;
  final VoidCallback? onTapSupervisor;

  const _ProfileCard({
    required this.profile,
    this.uploadingAvatar = false,
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
                    ? NetworkImage(ApiClient.resolveUrl(profile.avatarUrl!))
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
              if (uploadingAvatar)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Semantics(
                  label: 'Change profile picture',
                  button: true,
                  child: InkWell(
                    onTap: uploadingAvatar ? null : onEditAvatar,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(9),
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
          profile.adviser == null
              ? const MissingContactRow(
                  message: 'No OJT adviser assigned yet.',
                )
              : ProfileContactRow(
                  name: profile.adviser!.name,
                  subtitle: profile.adviser!.role,
                  onTap: onTapAdviser,
                ),
          const Divider(height: 1),
          profile.company == null
              ? const MissingContactRow(
                  message:
                      'Confirm your company details after completing the '
                      'OJT Requirements to see them here.',
                )
              : ProfileContactRow(
                  name: profile.company!.name,
                  subtitle: 'Your OJT Company',
                  onTap: onTapCompany,
                ),
          const Divider(height: 1),
          profile.supervisor == null
              ? const MissingContactRow(
                  message: 'No HR supervisor assigned yet.',
                )
              : ProfileContactRow(
                  name: profile.supervisor!.name,
                  subtitle: profile.supervisor!.role,
                  onTap: onTapSupervisor,
                ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/teacher_profile.dart';
import '../../services/api_client.dart';
import '../../services/teacher_profile_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/common/settings_tile.dart';
import '../../widgets/common/skeleton_list_tile.dart';

class TeacherProfileScreen extends StatefulWidget {
  final TeacherProfileService service;
  final VoidCallback onOpenHelpCenter;
  final VoidCallback onOpenSettings;
  final VoidCallback onLoggedOut;

  const TeacherProfileScreen({
    super.key,
    required this.service,
    required this.onOpenHelpCenter,
    required this.onOpenSettings,
    required this.onLoggedOut,
  });

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  TeacherProfile? _profile;
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
          content: Text('Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e'),
          backgroundColor: AppColors.statRedIcon,
        ),
      );
      return;
    }
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final avatarUrl = await widget.service.uploadAvatar(
        bytes: bytes,
        fileName: picked.name,
        contentType: _inferContentType(picked),
      );
      if (!mounted) return;
      setState(() {
        _profile = _profile!.copyWith(photoUrl: avatarUrl);
      });
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

  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool submitting = false;
    String? error;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() {
              submitting = true;
              error = null;
            });
            try {
              await widget.service.changePassword(
                currentPassword: currentController.text,
                newPassword: newController.text,
              );
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed.'),
                  backgroundColor: AppColors.successGreenText,
                ),
              );
            } on ApiException catch (e) {
              setDialogState(() {
                error = e.message;
                submitting = false;
              });
            }
          }

          return AlertDialog(
            title: const Text('Change Password'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error != null) ...[
                      Text(error!, style: const TextStyle(color: AppColors.statRedIcon)),
                      const SizedBox(height: 8),
                    ],
                    TextFormField(
                      controller: currentController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Current Password'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'New Password'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 8) return 'At least 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirm New Password'),
                      validator: (v) =>
                          v != newController.text ? 'Passwords do not match' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: submitting ? null : submit,
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showChangeEmailDialog() async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    bool submitting = false;
    String? error;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() {
              submitting = true;
              error = null;
            });
            try {
              final newEmail = await widget.service.changeEmail(
                currentPassword: passwordController.text,
                newEmail: emailController.text.trim(),
              );
              if (!mounted || !context.mounted) return;
              setState(() {
                _profile = _profile!.copyWith(email: newEmail);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email changed.'),
                  backgroundColor: AppColors.successGreenText,
                ),
              );
            } on ApiException catch (e) {
              setDialogState(() {
                error = e.message;
                submitting = false;
              });
            }
          }

          return AlertDialog(
            title: const Text('Change Email'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error != null) ...[
                      Text(error!, style: const TextStyle(color: AppColors.statRedIcon)),
                      const SizedBox(height: 8),
                    ],
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'New Email'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Current Password'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: submitting ? null : submit,
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
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

  String _joinOrPlaceholder(List<String> values) {
    return values.isEmpty ? 'Not set yet' : values.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: _loading || _profile == null
          ? const _ProfileSkeleton()
          : RefreshIndicator(
              color: AppColors.primaryMaroon,
              onRefresh: _load,
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
                          uploading: _uploadingAvatar,
                          onEditAvatar: _openAvatarPicker,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _DetailsCard(
                        title: 'Personal Details',
                        rows: [
                          _DetailRow(
                            Icons.school_outlined,
                            _joinOrPlaceholder(_profile!.programs),
                          ),
                          _DetailRow(
                            Icons.groups_outlined,
                            _joinOrPlaceholder(_profile!.sections),
                          ),
                          _DetailRow(Icons.email_outlined, _profile!.email),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Container(
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Security',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentOrange,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                            SettingsTile(
                              icon: Icons.alternate_email,
                              title: 'Change Email',
                              onTap: _showChangeEmailDialog,
                            ),
                            const Divider(height: 1),
                            SettingsTile(
                              icon: Icons.lock_outline,
                              title: 'Change Password',
                              onTap: _showChangePasswordDialog,
                            ),
                          ],
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
        const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonList(count: 3),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final TeacherProfile profile;
  final bool uploading;
  final VoidCallback onEditAvatar;

  const _ProfileCard({
    required this.profile,
    required this.uploading,
    required this.onEditAvatar,
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
                backgroundImage: profile.photoUrl != null
                    ? NetworkImage(ApiClient.resolveUrl(profile.photoUrl!))
                    : null,
                child: profile.photoUrl == null
                    ? Text(
                        profile.name.isNotEmpty
                            ? profile.name.substring(0, 1).toUpperCase()
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
                right: -4,
                bottom: -4,
                child: Semantics(
                  label: 'Change profile picture',
                  button: true,
                  child: InkWell(
                    onTap: uploading ? null : onEditAvatar,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMaroon,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: uploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
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
            profile.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            profile.position,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accentOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow {
  final IconData icon;
  final String value;

  const _DetailRow(this.icon, this.value);
}

class _DetailsCard extends StatelessWidget {
  final String title;
  final List<_DetailRow> rows;

  const _DetailsCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.accentOrange,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(row.icon, size: 15, color: AppColors.primaryMaroon),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

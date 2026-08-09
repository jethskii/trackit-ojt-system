import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/admin_profile.dart';
import '../../models/admin_session.dart';
import '../../services/admin_profile_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';

class AdminProfileScreen extends StatefulWidget {
  final ApiClient client;
  final AdminProfile admin;
  final ValueChanged<AdminProfile> onProfileUpdated;

  const AdminProfileScreen({
    super.key,
    required this.client,
    required this.admin,
    required this.onProfileUpdated,
  });

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late final AdminProfileService _service = AdminProfileService(widget.client);
  List<AdminSession> _sessions = [];
  bool _loadingSessions = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _loadingSessions = true);
    try {
      final sessions = await _service.getSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loadingSessions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSessions = false);
    }
  }

  Future<void> _terminateSession(AdminSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminate Session'),
        content: Text('End the session on "${session.device}"? That device will be signed out.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Terminate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.terminateSession(session.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session terminated.'),
          backgroundColor: AppColors.successGreenText,
        ),
      );
      _loadSessions();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.statRedIcon),
      );
    }
  }

  Future<void> _openEditProfileDialog() async {
    final nameController = TextEditingController(text: widget.admin.name);
    final emailController = TextEditingController(text: widget.admin.email);
    final formKey = GlobalKey<FormState>();
    Uint8List? pickedBytes;
    String? pickedFileName;
    String? pickedContentType;
    bool submitting = false;
    String? error;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickAvatar() async {
            final result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: const ['jpg', 'jpeg', 'png'],
              withData: true,
            );
            if (result == null || result.files.isEmpty) return;
            final file = result.files.single;
            if (file.bytes == null) return;
            if (file.size > 2 * 1024 * 1024) {
              setDialogState(() => error = 'Image must be 2MB or smaller.');
              return;
            }
            setDialogState(() {
              pickedBytes = file.bytes;
              pickedFileName = file.name;
              pickedContentType =
                  (file.extension?.toLowerCase() == 'png') ? 'image/png' : 'image/jpeg';
              error = null;
            });
          }

          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() {
              submitting = true;
              error = null;
            });
            try {
              final updated = await _service.updateProfile(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
                avatarBytes: pickedBytes,
                avatarFileName: pickedFileName,
                avatarContentType: pickedContentType ?? 'image/jpeg',
              );
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              widget.onProfileUpdated(updated);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated.'),
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
            title: const Text('Edit Profile'),
            content: SizedBox(
              width: 380,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (error != null) ...[
                        Text(
                          error!,
                          style: const TextStyle(color: AppColors.statRedIcon, fontSize: 13),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.background,
                              backgroundImage: pickedBytes != null
                                  ? MemoryImage(pickedBytes!)
                                  : (widget.admin.avatarUrl != null
                                        ? NetworkImage(
                                                ApiClient.resolveUrl(widget.admin.avatarUrl!),
                                              )
                                              as ImageProvider
                                        : null),
                              child: pickedBytes == null && widget.admin.avatarUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 32,
                                      color: AppColors.primaryMaroon,
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: InkWell(
                                onTap: pickAvatar,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
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
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          'JPG or PNG, up to 2MB',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: submitting ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  foregroundColor: Colors.white,
                ),
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openChangePasswordDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _ChangePasswordDialog(service: _service),
    );
  }

  Future<void> _openAllSessionsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _AllSessionsDialog(service: _service),
    );
    // The dialog may have terminated sessions -- refresh the card behind
    // it so it isn't showing stale state once the dialog closes.
    _loadSessions();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryMaroon,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Manage your account details and security.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _PersonalInfoCard(admin: widget.admin, onEdit: _openEditProfileDialog),
          const SizedBox(height: 16),
          _SecurityCard(admin: widget.admin, onChangePassword: _openChangePasswordDialog),
          const SizedBox(height: 16),
          _SessionsCard(
            sessions: _sessions,
            loading: _loadingSessions,
            onTerminate: _terminateSession,
            onViewAll: _openAllSessionsDialog,
          ),
        ],
      ),
    );
  }
}

class _PersonalInfoCard extends StatelessWidget {
  final AdminProfile admin;
  final VoidCallback onEdit;

  const _PersonalInfoCard({required this.admin, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 34,
      backgroundColor: AppColors.background,
      backgroundImage: admin.avatarUrl != null
          ? NetworkImage(ApiClient.resolveUrl(admin.avatarUrl!))
          : null,
      child: admin.avatarUrl == null
          ? Text(
              admin.name.isNotEmpty ? admin.name.substring(0, 1).toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryMaroon,
              ),
            )
          : null,
    );

    final editButton = OutlinedButton.icon(
      onPressed: onEdit,
      icon: const Icon(Icons.edit_outlined, size: 16),
      label: const Text('Edit Profile'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryMaroon,
        side: const BorderSide(color: AppColors.primaryMaroon),
      ),
    );

    return _Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 420;
          final details = Column(
            crossAxisAlignment: isNarrow
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                admin.name,
                textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                admin.email,
                textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statPurpleBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Administrator',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.statPurpleIcon,
                  ),
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              children: [
                avatar,
                const SizedBox(height: 12),
                details,
                const SizedBox(height: 14),
                SizedBox(width: double.infinity, child: editButton),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: 16),
              Expanded(child: details),
              editButton,
            ],
          );
        },
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  final AdminProfile admin;
  final VoidCallback onChangePassword;

  const _SecurityCard({required this.admin, required this.onChangePassword});

  @override
  Widget build(BuildContext context) {
    final isActive = admin.status.toLowerCase() == 'active';
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Security',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Password',
                  value: '••••••••',
                  icon: Icons.lock_outline,
                ),
              ),
              Expanded(
                child: _InfoTile(
                  label: 'Last Password Change',
                  value: admin.lastPasswordChange != null
                      ? DateFormat('MMM d, yyyy').format(admin.lastPasswordChange!)
                      : 'Never changed',
                  icon: Icons.history,
                ),
              ),
              Expanded(
                child: _InfoTile(
                  label: 'Account Status',
                  value: isActive ? 'Active' : admin.status,
                  icon: Icons.verified_user_outlined,
                  valueColor: isActive ? AppColors.successGreenText : AppColors.statRedIcon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: onChangePassword,
              icon: const Icon(Icons.lock_reset, size: 16),
              label: const Text('Change Password'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMaroon,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionsCard extends StatelessWidget {
  final List<AdminSession> sessions;
  final bool loading;
  final Future<void> Function(AdminSession session) onTerminate;
  final VoidCallback onViewAll;

  const _SessionsCard({
    required this.sessions,
    required this.loading,
    required this.onTerminate,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final preview = sessions.take(3).toList();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Connected Sessions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: sessions.isEmpty ? null : onViewAll,
                child: const Text('View All Sessions'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon)),
            )
          else if (preview.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No session activity yet.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            )
          else
            for (final session in preview) _SessionRow(session: session, onTerminate: onTerminate),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final AdminSession session;
  final Future<void> Function(AdminSession session) onTerminate;

  const _SessionRow({required this.session, required this.onTerminate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(
              session.device.toLowerCase().contains('app') ? Icons.smartphone : Icons.laptop_mac,
              size: 17,
              color: AppColors.primaryMaroon,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.device,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (session.current) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successGreenBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'This device',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.successGreenText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${session.ipAddress ?? 'Unknown IP'} · ${DateFormat('MMM d, h:mm a').format(session.loginAt)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (session.active && !session.current)
            IconButton(
              tooltip: 'Terminate session',
              onPressed: () => onTerminate(session),
              icon: const Icon(Icons.logout, size: 18, color: AppColors.statRedIcon),
            )
          else
            Text(
              session.active ? 'Active' : 'Ended',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: session.active ? AppColors.successGreenText : AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Fetches its own session list (rather than reusing a snapshot passed in
/// from the card behind it) so that terminating a session here updates
/// what's shown in the dialog immediately, not just in the card once the
/// dialog is closed.
class _AllSessionsDialog extends StatefulWidget {
  final AdminProfileService service;

  const _AllSessionsDialog({required this.service});

  @override
  State<_AllSessionsDialog> createState() => _AllSessionsDialogState();
}

class _AllSessionsDialogState extends State<_AllSessionsDialog> {
  List<AdminSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sessions = await widget.service.getSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _terminate(AdminSession session) async {
    try {
      await widget.service.terminateSession(session.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.statRedIcon),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('All Sessions'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryMaroon))
            : _sessions.isEmpty
            ? const Center(
                child: Text(
                  'No session activity yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : ListView.separated(
                itemCount: _sessions.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _SessionRow(session: _sessions[index], onTerminate: _terminate),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoTile({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

enum _PasswordStep { intro, otp, newPassword }

/// Mandatory email-OTP change-password flow: request a code -> verify it
/// (server hands back a short-lived reset token) -> set the new password.
/// A single dialog manages all three steps rather than three separate
/// modals, matching the spec's "click Change Password -> ... -> success"
/// as one continuous flow.
class _ChangePasswordDialog extends StatefulWidget {
  final AdminProfileService service;

  const _ChangePasswordDialog({required this.service});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  _PasswordStep _step = _PasswordStep.intro;
  bool _busy = false;
  String? _error;
  String? _maskedEmail;
  String? _resetToken;
  int _cooldown = 0;
  Timer? _timer;

  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _newPasswordFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final masked = await widget.service.requestPasswordOtp();
      if (!mounted) return;
      setState(() {
        _maskedEmail = masked;
        _step = _PasswordStep.otp;
        _busy = false;
      });
      _startCooldown();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await widget.service.verifyPasswordOtp(_codeController.text.trim());
      if (!mounted) return;
      setState(() {
        _resetToken = token;
        _step = _PasswordStep.newPassword;
        _busy = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  Future<void> _submitNewPassword() async {
    if (!_newPasswordFormKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.confirmPasswordChange(
        resetToken: _resetToken!,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully.'),
          backgroundColor: AppColors.successGreenText,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: AppColors.statRedIcon, fontSize: 13)),
                const SizedBox(height: 10),
              ],
              if (_step == _PasswordStep.intro)
                const Text(
                  "We'll send a one-time verification code to your registered email to confirm it's really you.",
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                )
              else if (_step == _PasswordStep.otp)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter the 6-digit code sent to ${_maskedEmail ?? 'your email'}.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Verification Code',
                        counterText: '',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: (_cooldown > 0 || _busy) ? null : _sendCode,
                        child: Text(_cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend Code'),
                      ),
                    ),
                  ],
                )
              else
                Form(
                  key: _newPasswordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Code verified. Set your new password.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newPasswordController,
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
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Confirm New Password'),
                        validator: (v) =>
                            v != _newPasswordController.text ? 'Passwords do not match' : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _busy
              ? null
              : switch (_step) {
                  _PasswordStep.intro => _sendCode,
                  _PasswordStep.otp => _verifyCode,
                  _PasswordStep.newPassword => _submitNewPassword,
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMaroon,
            foregroundColor: Colors.white,
          ),
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(switch (_step) {
                  _PasswordStep.intro => 'Send Code',
                  _PasswordStep.otp => 'Verify',
                  _PasswordStep.newPassword => 'Change Password',
                }),
        ),
      ],
    );
  }
}

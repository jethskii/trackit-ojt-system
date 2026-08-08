import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../models/student_profile.dart';
import '../../../services/api_client.dart';
import '../../../services/student_profile_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/skeleton_list_tile.dart';

class EditProfileScreen extends StatefulWidget {
  final StudentProfileService service;

  /// Called with the freshly saved profile so the rest of the app (Home
  /// tab's avatar/name, etc.) can update immediately instead of only
  /// after the next full login.
  final ValueChanged<StudentProfile> onProfileUpdated;

  const EditProfileScreen({
    super.key,
    required this.service,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();

  StudentProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await widget.service.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _nameController.text = profile.fullName;
      _mobileController.text = profile.mobileNumber == 'Not set' ? '' : profile.mobileNumber;
      _loading = false;
    });
  }

  bool get _nameCooldownActive {
    final availableAt = _profile?.nameChangeAvailableAt;
    return availableAt != null && availableAt.isAfter(DateTime.now());
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
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryMaroon),
              title: const Text('Choose from Gallery'),
              onTap: () => _pickAndUploadAvatar(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primaryMaroon),
              title: const Text('Take a Photo'),
              onTap: () => _pickAndUploadAvatar(ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final newName = _nameController.text.trim();
    final nameChanged = newName != _profile!.fullName;

    if (nameChanged && _nameCooldownActive) {
      // Defensive -- the field is read-only while cooldown is active, so
      // this shouldn't normally be reachable, but the server is still the
      // real authority either way.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cooldownMessage()), backgroundColor: AppColors.statRedIcon),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final updated = await widget.service.updateProfile(
        fullName: nameChanged ? newName : null,
        mobileNumber: _mobileController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _profile = updated);
      widget.onProfileUpdated(updated);
      final message = nameChanged && updated.nameChangeAvailableAt != null
          ? 'Name changed successfully. You can change it again on '
                '${DateFormat('MMMM d, yyyy').format(updated.nameChangeAvailableAt!)}.'
          : 'Profile updated.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.successGreenText),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Name change unavailable. ${e.message}'),
          backgroundColor: AppColors.statRedIcon,
        ),
      );
      // The server is authoritative -- refresh so the cooldown banner
      // (with the exact date) reflects reality even if our local state
      // was stale.
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reach the server. Is it running?'),
          backgroundColor: AppColors.statRedIcon,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _cooldownMessage() {
    final availableAt = _profile?.nameChangeAvailableAt;
    if (availableAt == null) return 'Name change unavailable right now.';
    final daysLeft = availableAt.difference(DateTime.now()).inDays + 1;
    return 'Name change unavailable. You recently changed your name. '
        'You can change it again in $daysLeft day${daysLeft == 1 ? '' : 's'} '
        '(${DateFormat('MMMM d, yyyy').format(availableAt)}).';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Edit Profile'),
          Expanded(
            child: _loading || _profile == null
                ? const SkeletonList(count: 3)
                : Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: AppColors.background,
                                backgroundImage: _profile!.avatarUrl != null
                                    ? NetworkImage(ApiClient.resolveUrl(_profile!.avatarUrl!))
                                    : null,
                                child: _profile!.avatarUrl == null
                                    ? Text(
                                        _profile!.fullName.isNotEmpty
                                            ? _profile!.fullName.substring(0, 1).toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryMaroon,
                                        ),
                                      )
                                    : null,
                              ),
                              if (_uploadingAvatar)
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
                                right: 0,
                                bottom: 0,
                                child: InkWell(
                                  onTap: _uploadingAvatar ? null : _openAvatarPicker,
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          readOnly: _nameCooldownActive,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            filled: _nameCooldownActive,
                            fillColor: AppColors.chipGrayBg,
                            suffixIcon: _nameCooldownActive
                                ? const Icon(Icons.lock_outline, size: 18)
                                : null,
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                        ),
                        if (_nameCooldownActive) ...[
                          const SizedBox(height: 6),
                          Text(
                            _cooldownMessage(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.statOrangeIcon,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Mobile Number'),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMaroon,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

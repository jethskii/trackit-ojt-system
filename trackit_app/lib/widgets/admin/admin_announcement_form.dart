import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/admin_announcement.dart';
import '../../services/admin_announcements_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';

/// The "Create Announcement" panel -- target audience, title, message,
/// and an optional image attachment. Reuses the exact image-picking flow
/// already proven for instructor announcements (image_picker XFile ->
/// bytes -> Image.memory preview -> multipart upload); PDF/DOCX
/// attachments from the original mockup aren't supported since that's a
/// materially different upload pipeline than what already exists.
class AdminAnnouncementForm extends StatefulWidget {
  final AdminAnnouncementsService service;
  final VoidCallback onCreated;

  const AdminAnnouncementForm({super.key, required this.service, required this.onCreated});

  @override
  State<AdminAnnouncementForm> createState() => _AdminAnnouncementFormState();
}

class _AdminAnnouncementFormState extends State<AdminAnnouncementForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  AdminAnnouncementAudience _audience = AdminAnnouncementAudience.all;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop();
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
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
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedImage = picked;
      _pickedImageBytes = bytes;
    });
  }

  void _openImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Add Attachment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryMaroon),
              title: const Text('Choose from Gallery'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primaryMaroon),
              title: const Text('Take a Photo'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _clearImage() => setState(() {
    _pickedImage = null;
    _pickedImageBytes = null;
  });

  void _clearAll() {
    setState(() {
      _titleController.clear();
      _contentController.clear();
      _audience = AdminAnnouncementAudience.all;
      _pickedImage = null;
      _pickedImageBytes = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.service.createAnnouncement(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        targetAudience: _audience,
        imageBytes: _pickedImageBytes,
        imageFileName: _pickedImage?.name,
        imageContentType: _pickedImage != null ? _inferContentType(_pickedImage!) : null,
      );
      if (!mounted) return;
      _clearAll();
      widget.onCreated();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Announcement published.')));
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
      if (mounted) setState(() => _saving = false);
    }
  }

  IconData _audienceIcon(AdminAnnouncementAudience a) {
    switch (a) {
      case AdminAnnouncementAudience.all:
        return Icons.check_circle;
      case AdminAnnouncementAudience.instructors:
        return Icons.groups_outlined;
      case AdminAnnouncementAudience.students:
        return Icons.school_outlined;
    }
  }

  Widget _buildAttachmentPicker() {
    if (_pickedImageBytes == null) {
      return InkWell(
        onTap: _openImagePicker,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.chipGrayBg, width: 1.4),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.upload_outlined, color: AppColors.textSecondary),
              SizedBox(height: 6),
              Text(
                'Click to Upload',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13),
              ),
              SizedBox(height: 2),
              Text(
                'JPG, PNG, WEBP (Max 5MB)',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.memory(_pickedImageBytes!, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _clearImage,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const Text(
                'Create Announcement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 18),
              const Text(
                'Target Audience',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final audience in AdminAnnouncementAudience.values)
                    _AudiencePill(
                      label: adminAudienceLabel(audience),
                      icon: _audienceIcon(audience),
                      selected: _audience == audience,
                      onTap: () => setState(() => _audience = audience),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter announcement title...',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Type your announcement here...',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Message is required' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Attachment (Optional)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              _buildAttachmentPicker(),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _clearAll,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.chipGrayBg),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMaroon,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_outlined, size: 16),
                      label: const Text('Publish Announcement'),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ),
    );
  }
}

class _AudiencePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AudiencePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryMaroon : AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

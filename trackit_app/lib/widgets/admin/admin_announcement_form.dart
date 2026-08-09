import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/admin_announcement.dart';
import '../../services/admin_announcements_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/attachment_kind.dart';

const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'doc', 'docx'];
const int _maxAttachmentBytes = 10 * 1024 * 1024;

String _contentTypeForExtension(String ext) {
  switch (ext.toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'pdf':
      return 'application/pdf';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    default:
      return 'application/octet-stream';
  }
}

/// The "Create Announcement" panel -- target audience, title, message,
/// and an optional attachment (image, PDF, or DOCX). Uses file_picker
/// (rather than image_picker, which only handles images) since an admin
/// announcement can carry a document, unlike instructor announcements.
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
  PlatformFile? _pickedFile;
  bool _picking = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final file = result.files.single;
      if (file.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read that file.'),
            backgroundColor: AppColors.statRedIcon,
          ),
        );
        return;
      }
      if (file.size > _maxAttachmentBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('That file is larger than 10MB.'),
            backgroundColor: AppColors.statRedIcon,
          ),
        );
        return;
      }
      setState(() => _pickedFile = file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the file picker: $e'), backgroundColor: AppColors.statRedIcon),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _clearAttachment() => setState(() => _pickedFile = null);

  void _clearAll() {
    setState(() {
      _titleController.clear();
      _contentController.clear();
      _audience = AdminAnnouncementAudience.all;
      _pickedFile = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final file = _pickedFile;
      final ext = file?.extension ?? '';
      await widget.service.createAnnouncement(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        targetAudience: _audience,
        attachmentBytes: file?.bytes,
        attachmentFileName: file?.name,
        attachmentContentType: file != null ? _contentTypeForExtension(ext) : null,
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

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildAttachmentPicker() {
    final file = _pickedFile;
    if (file == null) {
      return InkWell(
        onTap: _picking ? null : _pickAttachment,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.chipGrayBg, width: 1.4),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _picking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_outlined, color: AppColors.textSecondary),
              const SizedBox(height: 6),
              const Text(
                'Click to Upload',
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 2),
              const Text(
                'PDF, DOCX, JPG, PNG (Max 10MB)',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final kind = attachmentKindOf(file.name);
    if (kind == AttachmentKind.image && file.bytes != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.memory(file.bytes!, fit: BoxFit.cover),
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
                onTap: _clearAttachment,
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.chipGrayBg, width: 1.4),
      ),
      child: Row(
        children: [
          Icon(attachmentIconOf(kind), color: AppColors.primaryMaroon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatSize(file.size),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearAttachment,
            icon: const Icon(Icons.close, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
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

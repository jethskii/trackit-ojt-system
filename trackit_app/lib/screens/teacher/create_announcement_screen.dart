import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/announcement.dart';
import '../../models/instructor_class.dart';
import '../../services/api_client.dart';
import '../../services/teacher_announcements_service.dart';
import '../../services/teacher_classes_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/back_nav_header.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final TeacherAnnouncementsService announcementsService;
  final TeacherClassesService classesService;

  /// When set, the screen edits this announcement instead of creating a
  /// new one -- same form, pre-filled.
  final Announcement? existingAnnouncement;

  const CreateAnnouncementScreen({
    super.key,
    required this.announcementsService,
    required this.classesService,
    this.existingAnnouncement,
  });

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(
    text: widget.existingAnnouncement?.title,
  );
  late final _contentController = TextEditingController(
    text: widget.existingAnnouncement?.content,
  );
  List<InstructorClass> _classes = [];
  late final Set<int> _selectedClassIds = {
    for (final t in widget.existingAnnouncement?.targets ?? []) t.classId,
  };
  bool _loadingClasses = true;
  bool _saving = false;

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _removeExistingImage = false;

  bool get _isEditing => widget.existingAnnouncement != null;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final classes = await widget.classesService.getClasses();
    if (!mounted) return;
    setState(() {
      _classes = classes;
      if (!_isEditing && classes.length == 1) _selectedClassIds.add(classes.first.id);
      _loadingClasses = false;
    });
  }

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
    Navigator.of(context).pop(); // close the picker sheet
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
      _removeExistingImage = false;
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
              child: Text(
                'Add Image',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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

  void _clearImage() {
    setState(() {
      _pickedImage = null;
      _pickedImageBytes = null;
      _removeExistingImage = true;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one target section.'),
          backgroundColor: AppColors.statRedIcon,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      List<int>? imageBytes;
      String? imageFileName;
      String? imageContentType;
      if (_pickedImage != null && _pickedImageBytes != null) {
        imageBytes = _pickedImageBytes;
        imageFileName = _pickedImage!.name;
        imageContentType = _inferContentType(_pickedImage!);
      }

      if (_isEditing) {
        await widget.announcementsService.updateAnnouncement(
          id: widget.existingAnnouncement!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          classIds: _selectedClassIds.toList(),
          imageBytes: imageBytes,
          imageFileName: imageFileName,
          imageContentType: imageContentType,
          removeImage: _removeExistingImage,
        );
        if (!mounted) return;
        Navigator.of(context).pop('Announcement updated.');
      } else {
        await widget.announcementsService.createAnnouncement(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          classIds: _selectedClassIds.toList(),
          imageBytes: imageBytes,
          imageFileName: imageFileName,
          imageContentType: imageContentType,
        );
        if (!mounted) return;
        Navigator.of(context).pop('Announcement posted.');
      }
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

  Widget _buildImagePreview() {
    final existingUrl = widget.existingAnnouncement?.imageUrl;
    final showExisting = !_removeExistingImage && _pickedImageBytes == null && existingUrl != null;

    if (_pickedImageBytes == null && !showExisting) {
      return OutlinedButton.icon(
        onPressed: _openImagePicker,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Add Image (optional)'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryMaroon,
          side: const BorderSide(color: AppColors.primaryMaroon),
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(double.infinity, 0),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _pickedImageBytes != null
                ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                : Image.network(ApiClient.resolveUrl(existingUrl!), fit: BoxFit.cover),
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
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          BackNavHeader(
            subtitle: _isEditing ? 'Edit Announcement' : 'Create Announcement',
          ),
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contentController,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Content is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildImagePreview(),
                  const SizedBox(height: 16),
                  const Text(
                    'Target Section(s)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingClasses)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_classes.isEmpty)
                    const Text(
                      'Create a class first (Students tab) before posting an '
                      'announcement.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    )
                  else
                    for (final instructorClass in _classes)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primaryMaroon,
                        title: Text(
                          '${instructorClass.program} - ${instructorClass.section}',
                        ),
                        subtitle: Text(instructorClass.academicYear),
                        value: _selectedClassIds.contains(instructorClass.id),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedClassIds.add(instructorClass.id);
                            } else {
                              _selectedClassIds.remove(instructorClass.id);
                            }
                          });
                        },
                      ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving || _classes.isEmpty ? null : _submit,
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
                          : Text(_isEditing ? 'Save Changes' : 'Post Announcement'),
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

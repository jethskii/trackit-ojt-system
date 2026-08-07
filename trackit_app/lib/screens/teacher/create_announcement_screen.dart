import 'package:flutter/material.dart';
import '../../models/instructor_class.dart';
import '../../services/teacher_announcements_service.dart';
import '../../services/teacher_classes_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/back_nav_header.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final TeacherAnnouncementsService announcementsService;
  final TeacherClassesService classesService;

  const CreateAnnouncementScreen({
    super.key,
    required this.announcementsService,
    required this.classesService,
  });

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<InstructorClass> _classes = [];
  final Set<int> _selectedClassIds = {};
  bool _loadingClasses = true;
  bool _saving = false;

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
      if (classes.length == 1) _selectedClassIds.add(classes.first.id);
      _loadingClasses = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
    await widget.announcementsService.createAnnouncement(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      classIds: _selectedClassIds.toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop('Announcement posted.');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Create Announcement'),
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
                          : const Text('Post Announcement'),
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

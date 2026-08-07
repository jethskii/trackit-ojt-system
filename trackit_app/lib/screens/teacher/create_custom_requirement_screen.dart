import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/instructor_class.dart';
import '../../services/teacher_classes_service.dart';
import '../../services/teacher_requirements_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/back_nav_header.dart';

/// "+ Add New Requirement" -- an instructor-created Additional
/// Requirement, targeted at one or more of the instructor's own
/// sections. Real, submittable by students (see CustomRequirementsService
/// on the student side), not just a definition that sits unused.
class CreateCustomRequirementScreen extends StatefulWidget {
  final TeacherRequirementsService requirementsService;
  final TeacherClassesService classesService;

  const CreateCustomRequirementScreen({
    super.key,
    required this.requirementsService,
    required this.classesService,
  });

  @override
  State<CreateCustomRequirementScreen> createState() =>
      _CreateCustomRequirementScreenState();
}

class _CreateCustomRequirementScreenState
    extends State<CreateCustomRequirementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<InstructorClass> _classes = [];
  final Set<int> _selectedClassIds = {};
  DateTime? _deadline;
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
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
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
    await widget.requirementsService.createCustomRequirement(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      deadline: _deadline,
      classIds: _selectedClassIds.toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop('Requirement posted.');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Add New Requirement'),
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Requirement Name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined, color: AppColors.primaryMaroon),
                    title: Text(
                      _deadline == null
                          ? 'No deadline set'
                          : 'Deadline: ${DateFormat('MMM d, yyyy').format(_deadline!)}',
                    ),
                    trailing: TextButton(
                      onPressed: _pickDeadline,
                      child: Text(_deadline == null ? 'Set' : 'Change'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Target Section(s)',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingClasses)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_classes.isEmpty)
                    const Text(
                      'Create a class first (Students tab) before posting a '
                      'requirement.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    )
                  else
                    for (final instructorClass in _classes)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primaryMaroon,
                        title: Text('${instructorClass.program} - ${instructorClass.section}'),
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Post Requirement'),
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

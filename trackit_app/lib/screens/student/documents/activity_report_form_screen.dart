import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/activity_report.dart';
import '../../../models/student.dart';
import '../../../services/activity_reports_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/mock_file_picker_sheet.dart';

class ActivityReportFormScreen extends StatefulWidget {
  final ActivityReportsService service;
  final Student student;
  final ActivityReport? existingReport;

  const ActivityReportFormScreen({
    super.key,
    required this.service,
    required this.student,
    this.existingReport,
  });

  @override
  State<ActivityReportFormScreen> createState() =>
      _ActivityReportFormScreenState();
}

class _ActivityReportFormScreenState extends State<ActivityReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _hoursController;
  late final TextEditingController _descriptionController;
  late DateTime _date;
  late List<String> _attachments;
  bool _saving = false;

  bool get _isReadOnly {
    final status = widget.existingReport?.status;
    return status != null &&
        status != ActivityReportStatus.draft &&
        status != ActivityReportStatus.needsRevision;
  }

  @override
  void initState() {
    super.initState();
    final report = widget.existingReport;
    _titleController = TextEditingController(text: report?.title ?? '');
    _hoursController = TextEditingController(
      text: report != null ? _formatHours(report.hoursRendered) : '',
    );
    _descriptionController = TextEditingController(
      text: report?.description ?? '',
    );
    _date = report?.date ?? DateTime.now();
    _attachments = List.of(report?.attachments ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _hoursController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatHours(double hours) {
    return hours == hours.roundToDouble()
        ? hours.toInt().toString()
        : hours.toStringAsFixed(1);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _addAttachment() async {
    final fileName = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => const MockFilePickerSheet(label: 'Attachment'),
    );
    if (fileName == null) return;
    setState(() => _attachments.add(fileName));
  }

  void _removeAttachment(String attachment) {
    setState(() => _attachments.remove(attachment));
  }

  ActivityReport _buildReport(ActivityReportStatus status) {
    final hours = double.tryParse(_hoursController.text.trim()) ?? 0;
    return ActivityReport(
      id: widget.existingReport?.id ??
          'report-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      date: _date,
      company: widget.student.companyName,
      hoursRendered: hours,
      description: _descriptionController.text.trim(),
      attachments: _attachments,
      status: status,
    );
  }

  Future<void> _save(ActivityReportStatus status) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fix the highlighted fields before continuing.',
          ),
          backgroundColor: AppColors.statRedIcon,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final report = _buildReport(status);
    if (widget.existingReport == null) {
      await widget.service.createReport(report);
    } else {
      await widget.service.updateReport(report);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop(
      status == ActivityReportStatus.draft
          ? 'Report saved as draft.'
          : 'Report submitted successfully.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingReport != null;

    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          BackNavHeader(
            subtitle: isEditing ? 'Edit Activity Report' : 'New Activity Report',
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
                    enabled: !_isReadOnly,
                    decoration: const InputDecoration(labelText: 'Report Title'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _isReadOnly ? null : _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
                      child: Text(DateFormat('MMM d, yyyy').format(_date)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: widget.student.companyName,
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Company'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hoursController,
                    enabled: !_isReadOnly,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Hours Rendered',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Hours are required';
                      }
                      if (double.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_isReadOnly,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Description is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attachments',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (!_isReadOnly)
                        TextButton.icon(
                          onPressed: _addAttachment,
                          icon: const Icon(Icons.attach_file, size: 16),
                          label: const Text('Add'),
                        ),
                    ],
                  ),
                  for (final attachment in _attachments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.insert_drive_file_outlined,
                        color: AppColors.primaryMaroon,
                      ),
                      title: Text(attachment),
                      trailing: _isReadOnly
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Remove $attachment',
                              onPressed: () => _removeAttachment(attachment),
                            ),
                    ),
                  const SizedBox(height: 24),
                  if (!_isReadOnly)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => _save(ActivityReportStatus.draft),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryMaroon,
                              side: const BorderSide(
                                color: AppColors.primaryMaroon,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Save as Draft'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving
                                ? null
                                : () => _save(ActivityReportStatus.submitted),
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
                                : const Text('Submit'),
                          ),
                        ),
                      ],
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

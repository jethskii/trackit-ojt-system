import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/weekly_accomplishment_report.dart';
import '../../../services/activity_reports_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/mock_file_picker_sheet.dart';

class WeeklyReportFormScreen extends StatefulWidget {
  final ActivityReportsService service;
  final WeeklyAccomplishmentReport report;

  const WeeklyReportFormScreen({
    super.key,
    required this.service,
    required this.report,
  });

  @override
  State<WeeklyReportFormScreen> createState() => _WeeklyReportFormScreenState();
}

class _WeeklyReportFormScreenState extends State<WeeklyReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late List<String> _attachments;
  bool _saving = false;

  bool get _isReadOnly => widget.report.status == WeeklyReportStatus.approved;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.report.description ?? '',
    );
    _attachments = List.of(widget.report.attachments);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addAttachment() async {
    final fileName = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => const MockFilePickerSheet(label: 'Weekly Report'),
    );
    if (fileName == null) return;
    setState(() => _attachments.add(fileName));
  }

  void _removeAttachment(String attachment) {
    setState(() => _attachments.remove(attachment));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the highlighted fields before continuing.'),
          backgroundColor: AppColors.statRedIcon,
        ),
      );
      return;
    }
    if (_attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attach at least one file for this week\'s report.'),
          backgroundColor: AppColors.statRedIcon,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.service.submitReport(
      weekNumber: widget.report.weekNumber,
      description: _descriptionController.text.trim(),
      attachments: _attachments,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop('Week ${widget.report.weekNumber} report submitted.');
  }

  @override
  Widget build(BuildContext context) {
    final dateRange =
        '${DateFormat('MMM d').format(widget.report.weekStartDate)} - '
        '${DateFormat('MMM d, yyyy').format(widget.report.weekEndDate)}';

    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          BackNavHeader(subtitle: 'Week ${widget.report.weekNumber} Accomplishment Report'),
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Week Covered'),
                    child: Text(dateRange),
                  ),
                  const SizedBox(height: 12),
                  if (widget.report.remarks != null &&
                      widget.report.remarks!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.statRedBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Remarks: ${widget.report.remarks}',
                        style: const TextStyle(
                          color: AppColors.statRedIcon,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_isReadOnly,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Accomplishments This Week',
                      hintText:
                          'Summarize the tasks and accomplishments completed '
                          'during this week.',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'A summary of this week\'s accomplishments is required'
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _submit,
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
                            : Text(
                                widget.report.hasSubmission
                                    ? 'Re-submit Report'
                                    : 'Submit Report',
                              ),
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

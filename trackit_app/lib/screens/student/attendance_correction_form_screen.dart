import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/attendance_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/back_nav_header.dart';
import '../../widgets/common/mock_file_picker_sheet.dart';

/// Lets the student flag a problem with an attendance record (missed
/// clock-out, wrong time, etc.) for an instructor to review. There's no
/// Instructor module yet to actually approve/reject these, so every
/// submission stays pending -- the request is still persisted for real so
/// it shows up once that review flow exists.
class AttendanceCorrectionFormScreen extends StatefulWidget {
  final AttendanceService service;

  const AttendanceCorrectionFormScreen({super.key, required this.service});

  @override
  State<AttendanceCorrectionFormScreen> createState() =>
      _AttendanceCorrectionFormScreenState();
}

class _AttendanceCorrectionFormScreenState
    extends State<AttendanceCorrectionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reasonController;
  DateTime _workDate = DateTime.now();
  String? _attachmentFileName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _workDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _workDate = picked);
  }

  Future<void> _pickAttachment() async {
    final fileName = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => const MockFilePickerSheet(label: 'Proof'),
    );
    if (fileName == null) return;
    setState(() => _attachmentFileName = fileName);
  }

  void _removeAttachment() {
    setState(() => _attachmentFileName = null);
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
    setState(() => _saving = true);
    await widget.service.submitCorrectionRequest(
      workDate: _workDate,
      reason: _reasonController.text.trim(),
      attachmentFileName: _attachmentFileName,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop('Correction request submitted for review.');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Correction Request Form'),
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Attendance Date',
                      ),
                      child: Text(DateFormat('MMM d, yyyy').format(_workDate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Reason / Note',
                      hintText:
                          'Explain what happened (e.g. forgot to clock out, '
                          'wrong time recorded, task order from supervisor).',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'A reason is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Attachment (optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_attachmentFileName == null)
                        TextButton.icon(
                          onPressed: _pickAttachment,
                          icon: const Icon(Icons.attach_file, size: 16),
                          label: const Text('Add'),
                        ),
                    ],
                  ),
                  if (_attachmentFileName != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.insert_drive_file_outlined,
                        color: AppColors.primaryMaroon,
                      ),
                      title: Text(_attachmentFileName!),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Remove attachment',
                        onPressed: _removeAttachment,
                      ),
                    ),
                  const SizedBox(height: 24),
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
                          : const Text('Submit Request'),
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

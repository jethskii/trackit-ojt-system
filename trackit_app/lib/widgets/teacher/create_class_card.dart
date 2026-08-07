import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class CreateClassCard extends StatefulWidget {
  final Future<void> Function({
    required String program,
    required String section,
    required String academicYear,
  })
  onCreate;

  const CreateClassCard({super.key, required this.onCreate});

  @override
  State<CreateClassCard> createState() => _CreateClassCardState();
}

class _CreateClassCardState extends State<CreateClassCard> {
  final _formKey = GlobalKey<FormState>();
  final _programController = TextEditingController(text: 'BSIT');
  final _sectionController = TextEditingController();
  final _academicYearController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _programController.dispose();
    _sectionController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await widget.onCreate(
      program: _programController.text.trim(),
      section: _sectionController.text.trim(),
      academicYear: _academicYearController.text.trim(),
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.groups, size: 18, color: AppColors.primaryMaroon),
                SizedBox(width: 6),
                Text(
                  'Create Your Class',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "You'll get an activation code students use to join -- "
              'normally admin-generated, but there\'s no Admin module yet.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _programController,
                    decoration: const InputDecoration(labelText: 'Program'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sectionController,
                    decoration: const InputDecoration(labelText: 'Section'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _academicYearController,
              decoration: const InputDecoration(
                labelText: 'Academic Year',
                hintText: 'e.g. 2025-2026',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
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
                    : const Text('Create Class'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

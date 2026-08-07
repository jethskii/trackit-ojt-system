import 'package:flutter/material.dart';
import '../../../models/company_details.dart';
import '../../../services/student_profile_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/info_reminder_card.dart';

/// Manual-entry form for the student's OJT company, shown once all
/// Startup Requirements phases are complete. This is intentionally
/// self-reported (not auto-extracted from uploaded documents) so students
/// can correct any AI/OCR misreads, and becomes the source of truth for
/// the Home/Profile company card -- independent of the HTE Directory.
class ConfirmCompanyDetailsScreen extends StatefulWidget {
  final StudentProfileService service;
  final CompanyDetails? existingDetails;

  const ConfirmCompanyDetailsScreen({
    super.key,
    required this.service,
    this.existingDetails,
  });

  @override
  State<ConfirmCompanyDetailsScreen> createState() =>
      _ConfirmCompanyDetailsScreenState();
}

class _ConfirmCompanyDetailsScreenState
    extends State<ConfirmCompanyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _industryController;
  late final TextEditingController _supervisorController;
  late final TextEditingController _contactController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingDetails;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _addressController = TextEditingController(text: existing?.address ?? '');
    _industryController = TextEditingController(
      text: existing?.industry ?? '',
    );
    _supervisorController = TextEditingController(
      text: existing?.supervisorName ?? '',
    );
    _contactController = TextEditingController(
      text: existing?.contactNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _industryController.dispose();
    _supervisorController.dispose();
    _contactController.dispose();
    super.dispose();
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
    final details = CompanyDetails(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      industry: _industryController.text.trim(),
      supervisorName: _supervisorController.text.trim(),
      contactNumber: _contactController.text.trim(),
    );
    await widget.service.submitCompanyDetails(details);
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop('Company details confirmed.');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Confirm Company Details'),
          Expanded(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const InfoReminderCard(
                    message:
                        'Enter your company details manually so you can '
                        'correct any misreads from your uploaded documents. '
                        'This will appear on your Home and Profile pages.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Company name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Company Address',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Address is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _industryController,
                    decoration: const InputDecoration(labelText: 'Industry'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Industry is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _supervisorController,
                    decoration: const InputDecoration(
                      labelText: 'Supervisor Name',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Supervisor name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Supervisor Contact Number',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Contact number is required'
                        : null,
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
                          : const Text('Confirm Details'),
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

import 'package:flutter/material.dart';
import '../../models/hte_company.dart';
import '../../models/hte_company_contact.dart';
import '../../services/admin_hte_companies_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';

class _ContactFields {
  final TextEditingController name;
  final TextEditingController phone;

  _ContactFields({String name = '', String phone = ''})
    : name = TextEditingController(text: name),
      phone = TextEditingController(text: phone);

  void dispose() {
    name.dispose();
    phone.dispose();
  }
}

/// Full-page Add/Edit form, pushed over the whole shell (including the
/// sidebar) rather than embedded inline -- a CRUD form with a dynamic
/// contact-person list is a focused, heavier task than the rest of
/// Admin's inline two-pane screens, so it gets the same "push a screen"
/// treatment used elsewhere in the app for this kind of form.
class AdminHteCompanyFormScreen extends StatefulWidget {
  final AdminHteCompaniesService service;
  final HteCompany? existingCompany;

  const AdminHteCompanyFormScreen({
    super.key,
    required this.service,
    this.existingCompany,
  });

  @override
  State<AdminHteCompanyFormScreen> createState() => _AdminHteCompanyFormScreenState();
}

class _AdminHteCompanyFormScreenState extends State<AdminHteCompanyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existingCompany?.name);
  late final _industryController = TextEditingController(
    text: widget.existingCompany?.industry,
  );
  late final _locationController = TextEditingController(
    text: widget.existingCompany?.location,
  );
  late final _addressController = TextEditingController(text: widget.existingCompany?.address);
  late final _emailController = TextEditingController(text: widget.existingCompany?.email);
  late final _websiteController = TextEditingController(text: widget.existingCompany?.website);
  DateTime? _dateAccredited;
  late final List<_ContactFields> _contacts;
  bool _saving = false;

  bool get _isEditing => widget.existingCompany != null;

  @override
  void initState() {
    super.initState();
    _dateAccredited = widget.existingCompany?.dateAccredited;
    final existingContacts = widget.existingCompany?.contacts ?? const [];
    _contacts = existingContacts.isEmpty
        ? [_ContactFields()]
        : existingContacts.map((c) => _ContactFields(name: c.name, phone: c.phone)).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    for (final contact in _contacts) {
      contact.dispose();
    }
    super.dispose();
  }

  void _addContactRow() => setState(() => _contacts.add(_ContactFields()));

  void _removeContactRow(int index) {
    setState(() {
      _contacts[index].dispose();
      _contacts.removeAt(index);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateAccredited ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateAccredited = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final contacts = _contacts
        .where((c) => c.name.text.trim().isNotEmpty && c.phone.text.trim().isNotEmpty)
        .map((c) => HteCompanyContact(name: c.name.text.trim(), phone: c.phone.text.trim()))
        .toList();
    try {
      if (_isEditing) {
        await widget.service.updateCompany(
          id: widget.existingCompany!.id,
          name: _nameController.text.trim(),
          industry: _industryController.text.trim(),
          location: _locationController.text.trim(),
          address: _addressController.text.trim(),
          email: _emailController.text.trim(),
          website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
          dateAccredited: _dateAccredited,
          contacts: contacts,
        );
        if (!mounted) return;
        Navigator.of(context).pop('Company updated.');
      } else {
        await widget.service.createCompany(
          name: _nameController.text.trim(),
          industry: _industryController.text.trim(),
          location: _locationController.text.trim(),
          address: _addressController.text.trim(),
          email: _emailController.text.trim(),
          website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
          dateAccredited: _dateAccredited,
          contacts: contacts,
        );
        if (!mounted) return;
        Navigator.of(context).pop('Company added.');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.statRedIcon));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
        title: Text(_isEditing ? 'Edit HTE/Company' : 'Add HTE/Company'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Company Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _industryController,
                        decoration: const InputDecoration(labelText: 'Industry'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Industry is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'e.g. Taguig City',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Complete Address'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Email is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Website (optional)',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date HTE Accredited'),
                    child: Row(
                      children: [
                        Text(
                          _dateAccredited != null
                              ? '${_dateAccredited!.year}-${_dateAccredited!.month.toString().padLeft(2, '0')}-${_dateAccredited!.day.toString().padLeft(2, '0')}'
                              : 'Select date',
                          style: TextStyle(
                            color: _dateAccredited != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text(
                      'Available Contact Person(s)',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addContactRow,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Contact'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < _contacts.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _contacts[i].name,
                            decoration: const InputDecoration(labelText: 'Contact Name'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _contacts[i].phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Phone Number'),
                          ),
                        ),
                        IconButton(
                          onPressed: _contacts.length > 1 ? () => _removeContactRow(i) : null,
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                        ),
                      ],
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isEditing ? 'Save Changes' : 'Add Company'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

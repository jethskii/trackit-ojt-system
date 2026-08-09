import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/admin_instructor.dart';
import '../../services/admin_instructors_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';

// Below this width the info cards wrap to a single column instead of a row.
const _cardsWideBreakpoint = 640.0;

/// Embedded in AdminFacultyScreen's right-hand pane -- a ValueKey on
/// (instructorId, academicYear) on the caller's side forces a fresh
/// State whenever either changes, mirroring AdminClassDetailPanel.
class AdminInstructorDetailPanel extends StatefulWidget {
  final int instructorId;
  final String? academicYear;
  final AdminInstructorsService instructorsService;

  /// The Faculty list's status chips (Active/Inactive) go stale after
  /// Revoke/Reactivate/Edit -- this tells the parent to reload without
  /// this panel needing to know how that list is structured.
  final VoidCallback? onChanged;

  const AdminInstructorDetailPanel({
    super.key,
    required this.instructorId,
    required this.academicYear,
    required this.instructorsService,
    this.onChanged,
  });

  @override
  State<AdminInstructorDetailPanel> createState() => _AdminInstructorDetailPanelState();
}

class _AdminInstructorDetailPanelState extends State<AdminInstructorDetailPanel> {
  AdminInstructorDetail? _detail;
  bool _loading = true;
  String? _error;
  bool _regenerating = false;
  bool _busyStatus = false;
  String _studentQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await widget.instructorsService.getInstructorDetail(
        widget.instructorId,
        academicYear: widget.academicYear,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _copyCode() {
    if (_detail == null) return;
    Clipboard.setData(ClipboardData(text: _detail!.activationCode));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Activation code copied.')));
  }

  Future<void> _regenerateCode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Activation Code'),
        content: const Text(
          'The current code will stop working immediately for anyone who '
          "hasn't activated their account with it yet.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Regenerate')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _regenerating = true);
    try {
      await widget.instructorsService.regenerateActivationCode(widget.instructorId);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Activation code regenerated.')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  Future<void> _toggleStatus(bool activate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activate ? 'Reactivate Instructor' : 'Revoke Access'),
        content: Text(
          activate
              ? 'This instructor will be able to log in again.'
              : "This instructor's account will be immediately signed out and blocked from logging in until reactivated.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(activate ? 'Reactivate' : 'Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busyStatus = true);
    try {
      if (activate) {
        await widget.instructorsService.reactivate(widget.instructorId);
      } else {
        await widget.instructorsService.revokeAccess(widget.instructorId);
      }
      if (!mounted) return;
      await _load();
      widget.onChanged?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(activate ? 'Access reactivated.' : 'Access revoked.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyStatus = false);
    }
  }

  Future<void> _openEditDialog() async {
    final detail = _detail;
    if (detail == null) return;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: detail.name);
    final emailController = TextEditingController(text: detail.email);
    final phoneController = TextEditingController(text: detail.phone ?? '');
    final departmentController = TextEditingController(text: detail.department ?? '');
    final positionController = TextEditingController(text: detail.position ?? '');
    DateTime? dateHired = detail.dateHired;
    bool submitting = false;
    String? error;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickDateHired() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: dateHired ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) setDialogState(() => dateHired = picked);
          }

          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() {
              submitting = true;
              error = null;
            });
            try {
              await widget.instructorsService.updateInstructor(
                instructorId: widget.instructorId,
                name: nameController.text.trim(),
                email: emailController.text.trim(),
                phone: phoneController.text.trim(),
                department: departmentController.text.trim(),
                position: positionController.text.trim(),
                dateHired: dateHired,
              );
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              if (!mounted) return;
              await _load();
              widget.onChanged?.call();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Instructor information updated.')),
              );
            } on ApiException catch (e) {
              setDialogState(() {
                error = e.message;
                submitting = false;
              });
            }
          }

          return AlertDialog(
            title: const Text('Edit Information'),
            content: SizedBox(
              width: 380,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (error != null) ...[
                        Text(error!, style: const TextStyle(color: AppColors.statRedIcon, fontSize: 13)),
                        const SizedBox(height: 10),
                      ],
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Full Name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Phone Number'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: departmentController,
                        decoration: const InputDecoration(labelText: 'Department'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: positionController,
                        decoration: const InputDecoration(labelText: 'Position'),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined, color: AppColors.primaryMaroon),
                        title: Text(
                          dateHired == null
                              ? 'No hire date set'
                              : 'Date Hired: ${dateHired!.month}/${dateHired!.day}/${dateHired!.year}',
                        ),
                        trailing: TextButton(
                          onPressed: pickDateHired,
                          child: Text(dateHired == null ? 'Set' : 'Change'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: submitting ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  foregroundColor: Colors.white,
                ),
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<AdminInstructorStudent> get _filteredStudents {
    final students = _detail?.enrolledStudents ?? const [];
    if (_studentQuery.isEmpty) return students;
    final q = _studentQuery.toLowerCase();
    return students
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.email.toLowerCase().contains(q) ||
              (s.studentNumber?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(padding: EdgeInsets.all(16), child: SkeletonList());
    }
    if (_error != null || _detail == null) {
      return Center(
        child: EmptyStateView(
          icon: Icons.error_outline,
          title: 'Could not load this instructor',
          message: _error ?? 'Unknown error.',
          actionLabel: 'Retry',
          onAction: _load,
        ),
      );
    }

    // Guards against any single instructor's data shape (a legacy row,
    // an unexpected null) taking down the whole panel silently -- an
    // exception here surfaces as a real, readable error instead of a
    // blank pane with nothing to debug from.
    try {
      return _buildLoadedBody(_detail!, _filteredStudents);
    } catch (e) {
      return Center(
        child: EmptyStateView(
          icon: Icons.error_outline,
          title: 'Could not display this instructor',
          message: e.toString(),
          actionLabel: 'Retry',
          onAction: _load,
        ),
      );
    }
  }

  Widget _buildLoadedBody(AdminInstructorDetail detail, List<AdminInstructorStudent> filteredStudents) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(detail),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= _cardsWideBreakpoint;
              final cards = [
                _InfoCard(
                  title: 'Personal Information',
                  rows: [
                    _InfoRow(label: 'Email', value: detail.email),
                    _InfoRow(label: 'Phone Number', value: detail.phone?.isNotEmpty == true ? detail.phone! : 'Not set'),
                    _InfoRow(label: 'Full Name', value: detail.name),
                  ],
                ),
                _InfoCard(
                  title: 'Employment Information',
                  rows: [
                    _InfoRow(label: 'Department', value: detail.department ?? 'Not set'),
                    _InfoRow(label: 'Position', value: detail.position ?? 'Not set'),
                    _InfoRow(
                      label: 'Date Hired',
                      value: detail.dateHired != null
                          ? DateFormat('MMM d, yyyy').format(detail.dateHired!)
                          : 'Not set',
                    ),
                  ],
                ),
                _InfoCard(
                  title: 'Account Information',
                  rows: [
                    _InfoRow(
                      label: 'Activation Status',
                      value: detail.isActivated ? 'Activated' : 'Pending',
                    ),
                    _InfoRow(
                      label: 'Date Activated',
                      value: detail.activatedAt != null
                          ? DateFormat('MMM d, yyyy').format(detail.activatedAt!.toLocal())
                          : 'Not yet activated',
                    ),
                    _InfoRow(
                      label: 'Last Login',
                      value: detail.lastLoginAt != null
                          ? DateFormat('MMM d, yyyy h:mm a').format(detail.lastLoginAt!.toLocal())
                          : 'Never logged in',
                    ),
                    _InfoRow(label: 'Status', value: detail.isActive ? 'Active' : 'Inactive'),
                  ],
                ),
              ];
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    cards[i],
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _buildAssignedSectionCard(detail),
          const SizedBox(height: 12),
          _buildActivationCodeCard(detail),
          const SizedBox(height: 20),
          Text(
            'Enrolled Students: ${detail.totalEnrolled}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          if (detail.enrolledStudents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: EmptyStateView(
                  icon: Icons.groups_outlined,
                  title: 'No students currently assigned.',
                  message: detail.assignedSections.isEmpty
                      ? 'This instructor has no assigned section for A.Y. ${detail.academicYear ?? "the selected year"}.'
                      : 'This section has no enrolled students yet.',
                ),
              ),
            )
          else ...[
            TextField(
              onChanged: (v) => setState(() => _studentQuery = v),
              decoration: InputDecoration(
                hintText: 'Search student...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (filteredStudents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No matching students.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              )
            else
              _EnrolledStudentTable(students: filteredStudents),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(AdminInstructorDetail detail) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _cardsWideBreakpoint;
        final profileBlock = Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.background,
              backgroundImage: detail.avatarUrl != null
                  ? NetworkImage(ApiClient.resolveUrl(detail.avatarUrl!))
                  : null,
              child: detail.avatarUrl == null
                  ? const Icon(Icons.person_outline, size: 26, color: AppColors.primaryMaroon)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'Instructor ID: ${detail.instructorNumber}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: detail.isActive ? AppColors.successGreenBg : AppColors.statRedBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    detail.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: detail.isActive ? AppColors.successGreenText : AppColors.statRedIcon,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _openEditDialog,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Information'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryMaroon,
                side: const BorderSide(color: AppColors.primaryMaroon),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: (_busyStatus || !detail.isActive) ? null : () => _toggleStatus(false),
              icon: const Icon(Icons.block, size: 16),
              label: const Text('Revoke Access'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.statRedIcon,
                side: const BorderSide(color: AppColors.statRedIcon),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: (_busyStatus || detail.isActive) ? null : () => _toggleStatus(true),
              icon: const Icon(Icons.replay, size: 16),
              label: const Text('Reactivate'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.chipGrayBg),
              ),
            ),
          ],
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: profileBlock),
              actions,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [profileBlock, const SizedBox(height: 12), actions],
        );
      },
    );
  }

  Widget _buildAssignedSectionCard(AdminInstructorDetail detail) {
    final sections = detail.assignedSections;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assigned Section',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.3),
          ),
          const SizedBox(height: 6),
          if (sections.isEmpty)
            Text(
              'No section assigned for A.Y. ${detail.academicYear ?? "the selected year"}.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                for (final section in sections)
                  Text(
                    '${section.program} - ${section.section} (${section.studentCount} students)',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
              ],
            ),
          if (detail.academicYear != null) ...[
            const SizedBox(height: 4),
            Text(
              'Academic Year: ${detail.academicYear}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivationCodeCard(AdminInstructorDetail detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statOrangeBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructor Activation Code',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          const Text(
            'Give this code to the instructor to activate their account.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  detail.activationCode,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: AppColors.statOrangeIcon,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _copyCode,
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statOrangeIcon,
                  side: const BorderSide(color: AppColors.statOrangeIcon),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _regenerating ? null : _regenerateCode,
                icon: _regenerating
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.statOrangeIcon),
                      )
                    : const Icon(Icons.refresh, size: 14),
                label: const Text('Regenerate Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statOrangeIcon,
                  side: const BorderSide(color: AppColors.statOrangeIcon),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Created: ${DateFormat('MMM d, yyyy').format(detail.activationCodeCreatedAt.toLocal())}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EnrolledStudentTable extends StatelessWidget {
  final List<AdminInstructorStudent> students;

  const _EnrolledStudentTable({required this.students});

  static const _idWidth = 110.0;
  static const _nameWidth = 190.0;
  static const _emailWidth = 220.0;
  static const _sectionWidth = 120.0;
  static const _statusWidth = 100.0;

  double get _totalWidth => _idWidth + _nameWidth + _emailWidth + _sectionWidth + _statusWidth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _totalWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.background, width: 2)),
              ),
              child: Row(
                children: [
                  _headerCell('Student ID', _idWidth),
                  _headerCell('Student Name', _nameWidth),
                  _headerCell('Email', _emailWidth),
                  _headerCell('Section', _sectionWidth),
                  _headerCell('Account Status', _statusWidth),
                ],
              ),
            ),
            for (final student in students)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.background)),
                ),
                child: Row(
                  children: [
                    _cell(student.studentNumber ?? '--', _idWidth),
                    SizedBox(
                      width: _nameWidth,
                      child: Text(
                        student.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _cell(student.email, _emailWidth),
                    _cell(student.section, _sectionWidth),
                    SizedBox(
                      width: _statusWidth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: student.accountStatus == 'activated'
                              ? AppColors.successGreenBg
                              : AppColors.statOrangeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          student.accountStatus == 'activated' ? 'Activated' : 'Pending',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: student.accountStatus == 'activated'
                                ? AppColors.successGreenText
                                : AppColors.statOrangeIcon,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String label, double width) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _cell(String value, double width) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

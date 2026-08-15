import 'package:flutter/material.dart';
import '../../models/admin_overview.dart';
import '../../utils/app_colors.dart';
import '../../utils/ph_time.dart';
import '../../widgets/common/empty_state_view.dart';

// Every drill-down below is a real, standalone page reading from the same
// AdminOverview snapshot the dashboard already fetched -- no extra
// round-trip needed, since none of these lists are large enough to
// justify their own paginated endpoint.

class _DrillDownScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _DrillDownScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: SafeArea(child: child),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: AppColors.cardWhite,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _RowCard extends StatelessWidget {
  final Widget child;

  const _RowCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// ---------------- View Student List ----------------

class AdminOverviewStudentListScreen extends StatefulWidget {
  final List<AdminOverviewStudent> students;

  const AdminOverviewStudentListScreen({super.key, required this.students});

  @override
  State<AdminOverviewStudentListScreen> createState() => _AdminOverviewStudentListScreenState();
}

class _AdminOverviewStudentListScreenState extends State<AdminOverviewStudentListScreen> {
  String _query = '';

  List<AdminOverviewStudent> get _filtered {
    if (_query.isEmpty) return widget.students;
    final q = _query.toLowerCase();
    return widget.students
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              (s.program?.toLowerCase().contains(q) ?? false) ||
              (s.section?.toLowerCase().contains(q) ?? false) ||
              (s.instructorName?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  (String, Color, Color) _bucketStyle(AdminOverviewCompletionBucket bucket) {
    switch (bucket) {
      case AdminOverviewCompletionBucket.completed:
        return ('Completed', AppColors.successGreenBg, AppColors.successGreenText);
      case AdminOverviewCompletionBucket.ongoing:
        return ('Ongoing', AppColors.statBlueBg, AppColors.statBlueIcon);
      case AdminOverviewCompletionBucket.notStarted:
        return ('Not Started', AppColors.statOrangeBg, AppColors.statOrangeIcon);
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = _filtered;
    return _DrillDownScaffold(
      title: 'Student List (${widget.students.length})',
      child: Column(
        children: [
          _SearchField(hint: 'Search student, program, section, instructor...', onChanged: (v) => setState(() => _query = v)),
          Expanded(
            child: students.isEmpty
                ? const EmptyStateView(
                    icon: Icons.groups_outlined,
                    title: 'No students',
                    message: 'No students match this academic year or search.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: students.length,
                    itemBuilder: (context, i) {
                      final s = students[i];
                      final (label, bg, fg) = _bucketStyle(s.completionBucket);
                      return _RowCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.program ?? '--'} - ${s.section ?? '--'} | ${s.instructorName ?? 'Unassigned'}',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.completedHours.toStringAsFixed(1)} / ${s.requiredHours.toStringAsFixed(0)} hrs'
                                    '${s.accountActivated ? '' : ' -- account pending'}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            _Chip(label: label, bg: bg, fg: fg),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------- View Attendance List ----------------

class AdminOverviewAttendanceListScreen extends StatefulWidget {
  final List<AdminOverviewAttendanceEntry> entries;
  final int lateClockInHourPht;

  const AdminOverviewAttendanceListScreen({
    super.key,
    required this.entries,
    required this.lateClockInHourPht,
  });

  @override
  State<AdminOverviewAttendanceListScreen> createState() =>
      _AdminOverviewAttendanceListScreenState();
}

class _AdminOverviewAttendanceListScreenState extends State<AdminOverviewAttendanceListScreen> {
  String _query = '';
  AdminOverviewAttendanceStatus? _filter;

  List<AdminOverviewAttendanceEntry> get _filtered {
    var entries = widget.entries;
    if (_filter != null) entries = entries.where((e) => e.status == _filter).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      entries = entries
          .where(
            (e) =>
                e.name.toLowerCase().contains(q) ||
                (e.program?.toLowerCase().contains(q) ?? false) ||
                (e.section?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    return entries;
  }

  (String, Color, Color) _statusStyle(AdminOverviewAttendanceStatus status) {
    switch (status) {
      case AdminOverviewAttendanceStatus.clockedIn:
        return ('Clocked In', AppColors.successGreenBg, AppColors.successGreenText);
      case AdminOverviewAttendanceStatus.lateMissed:
        return ('Late / Missed', AppColors.statRedBg, AppColors.statRedIcon);
      case AdminOverviewAttendanceStatus.notYetClockedIn:
        return ('Not Yet Clocked In', AppColors.statOrangeBg, AppColors.statOrangeIcon);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filtered;
    return _DrillDownScaffold(
      title: "Today's Attendance (${widget.entries.length})",
      child: Column(
        children: [
          _SearchField(hint: 'Search student, program, section...', onChanged: (v) => setState(() => _query = v)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                _FilterChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                _FilterChip(
                  label: 'Clocked In',
                  selected: _filter == AdminOverviewAttendanceStatus.clockedIn,
                  onTap: () => setState(() => _filter = AdminOverviewAttendanceStatus.clockedIn),
                ),
                _FilterChip(
                  label: 'Not Yet',
                  selected: _filter == AdminOverviewAttendanceStatus.notYetClockedIn,
                  onTap: () => setState(() => _filter = AdminOverviewAttendanceStatus.notYetClockedIn),
                ),
                _FilterChip(
                  label: 'Late / Missed',
                  selected: _filter == AdminOverviewAttendanceStatus.lateMissed,
                  onTap: () => setState(() => _filter = AdminOverviewAttendanceStatus.lateMissed),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: entries.isEmpty
                ? const EmptyStateView(
                    icon: Icons.event_busy_outlined,
                    title: 'No matching students',
                    message: 'Try a different search or filter.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      final (label, bg, fg) = _statusStyle(e.status);
                      return _RowCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${e.program ?? '--'} - ${e.section ?? '--'}',
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                  ),
                                  if (e.clockIn != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'In ${formatPh(e.clockIn!, 'h:mm a')}'
                                      '${e.clockOut != null ? ' -- Out ${formatPh(e.clockOut!, 'h:mm a')}' : ''}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            _Chip(label: label, bg: bg, fg: fg),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryMaroon : AppColors.cardWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- View Hours Summary ----------------

class AdminOverviewHoursSummaryScreen extends StatefulWidget {
  final AdminOverview overview;

  const AdminOverviewHoursSummaryScreen({super.key, required this.overview});

  @override
  State<AdminOverviewHoursSummaryScreen> createState() => _AdminOverviewHoursSummaryScreenState();
}

class _AdminOverviewHoursSummaryScreenState extends State<AdminOverviewHoursSummaryScreen> {
  String _query = '';

  List<AdminOverviewStudent> get _filtered {
    final students = widget.overview.studentList;
    if (_query.isEmpty) return students;
    final q = _query.toLowerCase();
    return students.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final overview = widget.overview;
    final students = _filtered;
    return _DrillDownScaffold(
      title: 'OJT Hours Summary',
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: 'Rendered',
                    value: '${overview.totalHoursRendered.toStringAsFixed(0)} hrs',
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: 'Required',
                    value: '${overview.totalHoursRequired.toStringAsFixed(0)} hrs',
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: 'Completion',
                    value: '${overview.overallCompletionPercent.toStringAsFixed(1)}%',
                    valueColor: AppColors.primaryMaroon,
                  ),
                ),
              ],
            ),
          ),
          _SearchField(hint: 'Search student...', onChanged: (v) => setState(() => _query = v)),
          Expanded(
            child: students.isEmpty
                ? const EmptyStateView(
                    icon: Icons.timer_outlined,
                    title: 'No students',
                    message: 'No students match this academic year or search.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: students.length,
                    itemBuilder: (context, i) {
                      final s = students[i];
                      final pct = s.requiredHours > 0
                          ? (s.completedHours / s.requiredHours * 100).clamp(0, 100)
                          : 0.0;
                      return _RowCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct / 100,
                                      minHeight: 6,
                                      backgroundColor: AppColors.background,
                                      valueColor: const AlwaysStoppedAnimation(AppColors.primaryMaroon),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${s.completedHours.toStringAsFixed(1)}/${s.requiredHours.toStringAsFixed(0)} hrs',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: valueColor ?? AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ---------------- View At-Risk Students ----------------

class AdminOverviewAtRiskScreen extends StatelessWidget {
  final AdminOverview overview;

  const AdminOverviewAtRiskScreen({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final atRisk = overview.atRiskUnion;
    return _DrillDownScaffold(
      title: 'Students At Risk (${atRisk.length})',
      child: atRisk.isEmpty
          ? const EmptyStateView(
              icon: Icons.shield_outlined,
              title: 'No students at risk',
              message: 'Nobody currently meets the at-risk criteria for this academic year.',
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: atRisk.length,
              itemBuilder: (context, i) {
                final s = atRisk[i];
                return _RowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final reason in s.reasons)
                            _Chip(label: reason, bg: AppColors.statRedBg, fg: AppColors.statRedIcon),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ---------------- View All Tasks ----------------

class AdminOverviewTasksScreen extends StatelessWidget {
  final AdminOverview overview;

  const AdminOverviewTasksScreen({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    return _DrillDownScaffold(
      title: 'Pending Tasks (${overview.pendingTasksTotal})',
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          _TaskSection(
            title: 'Student Accounts Still Preparing',
            count: overview.accountsPreparing.length,
            children: [
              for (final a in overview.accountsPreparing)
                _RowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                      Text('${a.email} -- ${a.program ?? '--'} ${a.section ?? ''}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
            ],
          ),
          _TaskSection(
            title: 'Documents Awaiting Review',
            count: overview.documentsAwaitingReview.length,
            children: [
              for (final d in overview.documentsAwaitingReview)
                _RowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.requirementName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                      Text(
                        '${d.studentName}${d.submittedAt != null ? ' -- Submitted ${formatPh(d.submittedAt!, 'MMM d, yyyy')}' : ''}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          _TaskSection(
            title: 'Company Requests for Verification',
            count: overview.companyVerification.length,
            children: [
              for (final c in overview.companyVerification)
                _RowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                      Text(
                        '${c.companyName ?? 'Company not named'} -- ${c.program ?? '--'} ${c.section ?? ''}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          _TaskSection(
            title: 'Attendance Correction Requests',
            count: overview.correctionRequests.length,
            children: [
              for (final r in overview.correctionRequests)
                _RowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.studentName} -- ${formatPh(r.workDate, 'MMM d, yyyy')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                      ),
                      Text(r.reason, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskSection extends StatelessWidget {
  final String title;
  final int count;
  final List<Widget> children;

  const _TaskSection({required this.title, required this.count, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(
            '$title ($count)',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon),
          ),
        ),
        if (children.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Nothing pending.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          )
        else
          ...children,
      ],
    );
  }
}

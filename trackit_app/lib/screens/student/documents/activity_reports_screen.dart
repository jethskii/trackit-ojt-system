import 'package:flutter/material.dart';
import '../../../models/student.dart';
import '../../../models/weekly_accomplishment_report.dart';
import '../../../services/activity_reports_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/empty_state_view.dart';
import '../../../widgets/common/filter_chip_pill.dart';
import '../../../widgets/common/skeleton_list_tile.dart';
import '../../../widgets/student/documents/weekly_report_tile.dart';
import 'weekly_report_form_screen.dart';

/// Weekly Accomplishment Reports (AR): one recurring upload slot per OJT
/// week, generated from the student's OJT Start Date through the current
/// week. Purely a record/compilation -- no hours field, no link to
/// attendance or hours calculation.
class ActivityReportsScreen extends StatefulWidget {
  final ActivityReportsService service;
  final Student student;

  const ActivityReportsScreen({
    super.key,
    required this.service,
    required this.student,
  });

  @override
  State<ActivityReportsScreen> createState() => _ActivityReportsScreenState();
}

class _ActivityReportsScreenState extends State<ActivityReportsScreen> {
  List<WeeklyAccomplishmentReport> _reports = [];
  bool _loading = true;
  WeeklyReportStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    if (widget.student.ojtStartDate != null) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    final reports = await widget.service.getReports();
    if (!mounted) return;
    setState(() {
      _reports = reports..sort((a, b) => b.weekNumber.compareTo(a.weekNumber));
      _loading = false;
    });
  }

  List<WeeklyAccomplishmentReport> get _filtered {
    if (_statusFilter == null) return _reports;
    return _reports.where((r) => r.status == _statusFilter).toList();
  }

  Future<void> _openForm(WeeklyAccomplishmentReport report) async {
    final confirmation = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => WeeklyReportFormScreen(
          service: widget.service,
          report: report,
        ),
      ),
    );
    await _load();
    if (confirmation != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(confirmation),
          backgroundColor: AppColors.successGreenText,
        ),
      );
    }
  }

  Future<void> _refresh() => _load();

  String _statusLabel(WeeklyReportStatus status) {
    switch (status) {
      case WeeklyReportStatus.missing:
        return 'Missing';
      case WeeklyReportStatus.submitted:
        return 'Submitted';
      case WeeklyReportStatus.approved:
        return 'Approved';
      case WeeklyReportStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Activity Reports'),
          Expanded(
            child: widget.student.ojtStartDate == null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      EmptyStateView(
                        icon: Icons.assignment_outlined,
                        title: 'No weekly reports yet',
                        message:
                            'Confirm your company details in OJT '
                            'Requirements first -- weekly report slots are '
                            'generated from your OJT Start Date.',
                      ),
                    ],
                  )
                : _loading
                    ? const SkeletonList()
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: SizedBox(
                              height: 36,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  FilterChipPill(
                                    label: 'All',
                                    selected: _statusFilter == null,
                                    onTap: () =>
                                        setState(() => _statusFilter = null),
                                  ),
                                  for (final status in WeeklyReportStatus.values)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: FilterChipPill(
                                        label: _statusLabel(status),
                                        selected: _statusFilter == status,
                                        onTap: () =>
                                            setState(() => _statusFilter = status),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: RefreshIndicator(
                              color: AppColors.primaryMaroon,
                              onRefresh: _refresh,
                              child: _filtered.isEmpty
                                  ? ListView(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      children: [
                                        EmptyStateView(
                                          icon: Icons.assignment_outlined,
                                          title: _reports.isEmpty
                                              ? 'No weekly reports yet'
                                              : 'No matching reports',
                                          message: _reports.isEmpty
                                              ? 'Your first weekly report slot '
                                                  'will appear here once your '
                                                  'OJT week begins.'
                                              : 'Try a different filter.',
                                        ),
                                      ],
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        24,
                                      ),
                                      itemCount: _filtered.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final report = _filtered[index];
                                        return WeeklyReportTile(
                                          report: report,
                                          onTap: () => _openForm(report),
                                        );
                                      },
                                    ),
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

import 'package:flutter/material.dart';
import '../../../models/activity_report.dart';
import '../../../models/student.dart';
import '../../../services/activity_reports_service.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/common/back_nav_header.dart';
import '../../../widgets/common/filter_chip_pill.dart';
import '../../../widgets/student/documents/activity_report_card.dart';
import 'activity_report_form_screen.dart';

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
  List<ActivityReport> _reports = [];
  bool _loading = true;
  String _query = '';
  ActivityReportStatus? _statusFilter;
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reports = await widget.service.getReports();
    if (!mounted) return;
    setState(() {
      _reports = reports;
      _loading = false;
    });
  }

  List<ActivityReport> get _filtered {
    final list = _reports.where((r) {
      final matchesQuery =
          _query.isEmpty || r.title.toLowerCase().contains(_query.toLowerCase());
      final matchesStatus = _statusFilter == null || r.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
    list.sort(
      (a, b) => _sortDescending
          ? b.date.compareTo(a.date)
          : a.date.compareTo(b.date),
    );
    return list;
  }

  Future<void> _openForm({ActivityReport? report}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActivityReportFormScreen(
          service: widget.service,
          student: widget.student,
          existingReport: report,
        ),
      ),
    );
    _load();
  }

  String _statusLabel(ActivityReportStatus status) {
    switch (status) {
      case ActivityReportStatus.draft:
        return 'Draft';
      case ActivityReportStatus.submitted:
        return 'Submitted';
      case ActivityReportStatus.reviewed:
        return 'Reviewed';
      case ActivityReportStatus.approved:
        return 'Approved';
      case ActivityReportStatus.needsRevision:
        return 'Needs Revision';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryMaroon,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            const BackNavHeader(subtitle: 'Activity Reports'),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryMaroon,
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: TextField(
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              hintText: 'Search reports...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: AppColors.cardWhite,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
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
                                      for (final status
                                          in ActivityReportStatus.values)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          child: FilterChipPill(
                                            label: _statusLabel(status),
                                            selected: _statusFilter == status,
                                            onTap: () => setState(
                                              () => _statusFilter = status,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(
                                  () => _sortDescending = !_sortDescending,
                                ),
                                icon: Icon(
                                  _sortDescending
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: AppColors.primaryMaroon,
                                ),
                                tooltip: 'Sort by date',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: _filtered.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No activity reports yet.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    80,
                                  ),
                                  itemCount: _filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final report = _filtered[index];
                                    return ActivityReportCard(
                                      report: report,
                                      onTap: () => _openForm(report: report),
                                    );
                                  },
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
}

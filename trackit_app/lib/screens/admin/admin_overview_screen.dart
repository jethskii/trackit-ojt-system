import 'package:flutter/material.dart';
import '../../models/admin_class.dart';
import '../../models/admin_overview.dart';
import '../../services/admin_classes_service.dart';
import '../../services/admin_overview_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_colors.dart';
import '../../utils/ph_time.dart';
import '../../widgets/admin/academic_year_picker.dart';
import '../../widgets/admin/donut_chart.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';
import 'admin_overview_detail_screens.dart';

const _wideBreakpoint = 980.0;
const _cardsWideBreakpoint = 700.0;

/// The Admin's central monitoring dashboard -- entirely computed from
/// real data via GET /api/admin/overview (one aggregation endpoint,
/// mirroring teacherDashboard.js's shape but school-wide and
/// year-scoped). This is a from-scratch replacement of what used to live
/// here (the Sections/Faculty browsing UI, now merged into Class
/// Management) -- Overview's job is now purely "summarize the system,"
/// not "browse and manage it."
class AdminOverviewScreen extends StatefulWidget {
  final ApiClient client;
  final String adminName;

  const AdminOverviewScreen({super.key, required this.client, required this.adminName});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  late final AdminClassesService _classesService = HttpAdminClassesService(widget.client);
  late final AdminOverviewService _overviewService = HttpAdminOverviewService(widget.client);

  List<AdminAcademicYear> _years = [];
  String? _selectedYear;
  bool _yearsLoading = true;
  String? _yearsError;

  AdminOverview? _overview;
  bool _overviewLoading = true;
  String? _overviewError;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  String _suggestedAcademicYear() {
    final now = DateTime.now();
    final startYear = now.month >= 8 ? now.year : now.year - 1;
    return '$startYear-${startYear + 1}';
  }

  Future<void> _loadYears() async {
    setState(() {
      _yearsLoading = true;
      _yearsError = null;
    });
    try {
      final years = await _classesService.getAcademicYears();
      if (!mounted) return;
      final working = years.isEmpty
          ? [AdminAcademicYear(year: _suggestedAcademicYear(), classCount: 0, isCurrent: true)]
          : years;
      final target = _selectedYear ??
          working.firstWhere((y) => y.isCurrent, orElse: () => working.first).year;
      setState(() {
        _years = working;
        _selectedYear = target;
        _yearsLoading = false;
      });
      await _loadOverview(target);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _yearsError = e.toString();
        _yearsLoading = false;
      });
    }
  }

  Future<void> _loadOverview(String year) async {
    setState(() {
      _overviewLoading = true;
      _overviewError = null;
    });
    try {
      final overview = await _overviewService.getOverview(academicYear: year);
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _overviewLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _overviewError = e.toString();
        _overviewLoading = false;
      });
    }
  }

  Future<void> _selectYear(String year) async {
    if (year == _selectedYear) return;
    setState(() => _selectedYear = year);
    await _loadOverview(year);
  }

  String get _greeting {
    final hour = nowInPh().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    if (_yearsLoading) return const SkeletonList();
    if (_yearsError != null) {
      return EmptyStateView(
        icon: Icons.error_outline,
        title: 'Could not load academic years',
        message: _yearsError!,
        actionLabel: 'Retry',
        onAction: _loadYears,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isWide),
              const SizedBox(height: 18),
              if (_overviewLoading)
                const Padding(padding: EdgeInsets.only(top: 40), child: SkeletonList())
              else if (_overviewError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyStateView(
                    icon: Icons.error_outline,
                    title: 'Could not load the overview',
                    message: _overviewError!,
                    actionLabel: 'Retry',
                    onAction: () => _loadOverview(_selectedYear!),
                  ),
                )
              else
                _buildDashboard(_overview!, isWide),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isWide) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$_greeting, ${widget.adminName.split(' ').first}! \u{1F44B}',
          style: TextStyle(
            fontSize: isWide ? 22 : 19,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryMaroon,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          "Here's today's OJT overview.",
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AcademicYearPicker(years: _years, selected: _selectedYear, onSelected: _selectYear),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _overviewLoading ? null : () => _loadOverview(_selectedYear!),
          icon: const Icon(Icons.refresh, color: AppColors.primaryMaroon),
        ),
      ],
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: titleBlock), controls],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [titleBlock, const SizedBox(height: 12), controls],
    );
  }

  Widget _buildDashboard(AdminOverview overview, bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatCards(overview, isWide),
        const SizedBox(height: 16),
        _buildCharts(overview, isWide),
        const SizedBox(height: 16),
        _buildBottomRow(overview, isWide),
      ],
    );
  }

  Widget _buildStatCards(AdminOverview overview, bool isWide) {
    final attendancePct = overview.totalStudents > 0
        ? (overview.clockedInToday / overview.totalStudents * 100)
        : 0.0;
    final completedPct = overview.totalStudents > 0
        ? (overview.completedCount / overview.totalStudents * 100)
        : 0.0;
    final cards = [
      _StatCard(
        icon: Icons.groups_outlined,
        iconBg: AppColors.statBlueBg,
        iconColor: AppColors.statBlueIcon,
        label: 'Total OJT Students',
        value: '${overview.totalStudents}',
        subtitle: 'Currently enrolled / active',
      ),
      _StatCard(
        icon: Icons.person_outline,
        iconBg: AppColors.statRedBg,
        iconColor: AppColors.statRedIcon,
        label: 'Total Instructors / Supervisors',
        value: '${overview.totalInstructors}',
        subtitle: 'Handling OJT students',
      ),
      _StatCard(
        icon: Icons.check_circle_outline,
        iconBg: AppColors.successGreenBg,
        iconColor: AppColors.successGreenText,
        label: 'Clocked In Today',
        value: '${overview.clockedInToday} / ${overview.totalStudents}',
        subtitle: '${attendancePct.toStringAsFixed(1)}% clocked in',
        subtitleColor: AppColors.successGreenText,
      ),
      _StatCard(
        icon: Icons.emoji_events_outlined,
        iconBg: AppColors.statOrangeBg,
        iconColor: AppColors.statOrangeIcon,
        label: 'OJT Students Completed',
        value: '${overview.completedCount}',
        subtitle: '${completedPct.toStringAsFixed(1)}% of total students',
      ),
    ];

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            Expanded(child: cards[i]),
          ],
        ],
      );
    }
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [for (final c in cards) SizedBox(width: 260, child: c)],
    );
  }

  Widget _buildCharts(AdminOverview overview, bool isWide) {
    final attendanceCard = _ChartCard(
      title: "TODAY'S ATTENDANCE OVERVIEW",
      chart: DonutChart(
        centerLabel: '${overview.clockedInToday}',
        centerSubLabel: 'Clocked In Today\n/${overview.totalStudents}',
        segments: [
          DonutSegment(label: 'Clocked In', value: overview.clockedInToday, color: AppColors.successGreenText),
          DonutSegment(label: 'Not Yet Clocked In', value: overview.notYetClockedInToday, color: AppColors.statOrangeIcon),
          DonutSegment(label: 'Late / Missed', value: overview.lateMissedToday, color: AppColors.statRedIcon),
        ],
      ),
      footer: overview.totalStudents == 0
          ? null
          : Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.successGreenBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      overview.clockedInToday == overview.totalStudents
                          ? 'Great job! Everyone has clocked in today.'
                          : '${overview.notYetClockedInToday + overview.lateMissedToday} student'
                                '${(overview.notYetClockedInToday + overview.lateMissedToday) == 1 ? '' : 's'} '
                                'still need${(overview.notYetClockedInToday + overview.lateMissedToday) == 1 ? 's' : ''} to clock in.',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.successGreenText, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
      buttonLabel: 'View Attendance List',
      onPressed: () => _push(
        AdminOverviewAttendanceListScreen(
          entries: overview.attendanceList,
          lateClockInHourPht: overview.lateClockInHourPht,
        ),
      ),
    );

    final completionCard = _ChartCard(
      title: 'OJT COMPLETION STATUS',
      chart: DonutChart(
        centerLabel: '${overview.totalStudents}',
        centerSubLabel: 'Total Students',
        segments: [
          DonutSegment(label: 'Completed', value: overview.completedCount, color: AppColors.successGreenText),
          DonutSegment(label: 'Ongoing', value: overview.ongoingCount, color: AppColors.statBlueIcon),
          DonutSegment(label: 'Not Started', value: overview.notStartedCount, color: AppColors.statOrangeIcon),
        ],
      ),
      buttonLabel: 'View Student List',
      onPressed: () => _push(AdminOverviewStudentListScreen(students: overview.studentList)),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: attendanceCard),
          const SizedBox(width: 14),
          Expanded(child: completionCard),
        ],
      );
    }
    return Column(
      children: [attendanceCard, const SizedBox(height: 14), completionCard],
    );
  }

  Widget _buildBottomRow(AdminOverview overview, bool isWide) {
    final tasksCard = _PendingTasksCard(overview: overview, onViewAll: () => _push(AdminOverviewTasksScreen(overview: overview)));
    final hoursCard = _HoursCard(overview: overview, onViewSummary: () => _push(AdminOverviewHoursSummaryScreen(overview: overview)));
    final atRiskCard = _AtRiskCard(overview: overview, onViewAll: () => _push(AdminOverviewAtRiskScreen(overview: overview)));

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tasksCard),
          const SizedBox(width: 14),
          Expanded(child: hoursCard),
          const SizedBox(width: 14),
          Expanded(child: atRiskCard),
        ],
      );
    }
    return Column(
      children: [tasksCard, const SizedBox(height: 14), hoursCard, const SizedBox(height: 14), atRiskCard],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final Color? subtitleColor;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 11, color: subtitleColor ?? AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget chart;
  final Widget? footer;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _ChartCard({
    required this.title,
    required this.chart,
    this.footer,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.4)),
          const SizedBox(height: 16),
          chart,
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= _cardsWideBreakpoint;
              final button = OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryMaroon,
                  side: const BorderSide(color: AppColors.primaryMaroon),
                ),
                child: Text(buttonLabel),
              );
              if (footer == null) return Align(alignment: Alignment.centerRight, child: button);
              if (wide) {
                return Row(
                  children: [Expanded(child: footer!), const SizedBox(width: 10), button],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [footer!, const SizedBox(height: 10), Align(alignment: Alignment.centerRight, child: button)],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PendingTasksCard extends StatelessWidget {
  final AdminOverview overview;
  final VoidCallback onViewAll;

  const _PendingTasksCard({required this.overview, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.person_add_alt_outlined,
        label: 'Student accounts still preparing',
        subtitle: 'Awaiting account activation',
        count: overview.accountsPreparing.length,
      ),
      (
        icon: Icons.description_outlined,
        label: 'Documents awaiting review / validation',
        subtitle: 'Uploaded by students',
        count: overview.documentsAwaitingReview.length,
      ),
      (
        icon: Icons.apartment_outlined,
        label: 'Company requests for verification',
        subtitle: 'For evaluation',
        count: overview.companyVerification.length,
      ),
      (
        icon: Icons.edit_note_outlined,
        label: 'Attendance correction requests',
        subtitle: 'For review',
        count: overview.correctionRequests.length,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ADMIN PENDING TASKS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.4)),
          const SizedBox(height: 12),
          if (overview.pendingTasksTotal == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nothing pending right now.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            )
          else
            for (final item in items)
              if (item.count > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: Icon(item.icon, size: 16, color: AppColors.primaryMaroon),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text(item.subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.statRedBg, borderRadius: BorderRadius.circular(20)),
                        child: Text('${item.count}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.statRedIcon)),
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: const Text('View all tasks'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryMaroon),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursCard extends StatelessWidget {
  final AdminOverview overview;
  final VoidCallback onViewSummary;

  const _HoursCard({required this.overview, required this.onViewSummary});

  @override
  Widget build(BuildContext context) {
    final pct = (overview.overallCompletionPercent / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('OVERALL OJT HOURS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.4)),
          const SizedBox(height: 4),
          const Text('Total accumulated hours rendered by all students', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.statRedBg, borderRadius: BorderRadius.circular(10)),
                alignment: Alignment.center,
                child: const Icon(Icons.access_time, color: AppColors.statRedIcon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_formatHours(overview.totalHoursRendered)} hrs', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const Text('Total Hours Rendered', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Required Hours\n(All Active Students)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text('${_formatHours(overview.totalHoursRequired)} hrs', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Overall Completion', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text('${overview.overallCompletionPercent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.primaryMaroon)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation(AppColors.primaryMaroon),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onViewSummary,
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: const Text('View Hours Summary'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryMaroon),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHours(double hours) => hours == hours.roundToDouble() ? hours.toInt().toString() : hours.toStringAsFixed(1);
}

class _AtRiskCard extends StatelessWidget {
  final AdminOverview overview;
  final VoidCallback onViewAll;

  const _AtRiskCard({required this.overview, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Below 50% of required hours', overview.belowHalfHours.length),
      ('No attendance this week', overview.noAttendanceThisWeek.length),
      ('Behind schedule (based on days elapsed)', overview.behindSchedule.length),
    ];
    final totalAtRisk = overview.atRiskUnion.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('STUDENTS AT RISK', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.4)),
          const SizedBox(height: 4),
          const Text('Students who may need attention', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          if (totalAtRisk == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No students currently at risk.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(item.$1, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                    Text('${item.$2}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.statRedIcon)),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: const Text('View At-Risk Students'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryMaroon),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance.dart';
import '../../models/attendance_correction_request.dart';
import '../../services/attendance_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/back_nav_header.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';
import '../../widgets/common/status_badge.dart';

/// Full chronological attendance log ("View All" from the Attendance tab),
/// plus the student's own Correction Request submissions so they can check
/// whether an instructor has acted on them yet (no Instructor module exists
/// to actually do that review yet -- see AttendanceCorrectionRequest).
class AttendanceHistoryScreen extends StatefulWidget {
  final AttendanceService service;

  const AttendanceHistoryScreen({super.key, required this.service});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<AttendanceHistoryEntry> _history = [];
  List<AttendanceCorrectionRequest> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.service.getHistory(),
      widget.service.getCorrectionRequests(),
    ]);
    if (!mounted) return;
    setState(() {
      _history = results[0] as List<AttendanceHistoryEntry>;
      _requests = results[1] as List<AttendanceCorrectionRequest>;
      _loading = false;
    });
  }

  Future<void> _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          const BackNavHeader(subtitle: 'Attendance History'),
          Expanded(
            child: _loading
                ? const SkeletonList()
                : RefreshIndicator(
                    color: AppColors.primaryMaroon,
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      children: [
                        const Text(
                          'Full Log',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_history.isEmpty)
                          const EmptyStateView(
                            icon: Icons.event_busy_outlined,
                            title: 'No attendance records yet',
                            message:
                                'Your clock-in and clock-out history will '
                                'appear here once you start logging '
                                'attendance.',
                          )
                        else
                          for (final entry in _history) _HistoryRow(entry: entry),
                        const SizedBox(height: 24),
                        const Text(
                          'Correction Requests',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_requests.isEmpty)
                          const EmptyStateView(
                            icon: Icons.edit_document,
                            title: 'No correction requests',
                            message:
                                'Requests you submit to fix an attendance '
                                'record will appear here with their review '
                                'status.',
                          )
                        else
                          for (final request in _requests)
                            _CorrectionRequestRow(request: request),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final AttendanceHistoryEntry entry;

  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d, yyyy').format(entry.date);
    final clockInLabel = entry.clockIn != null
        ? DateFormat('hh:mm a').format(entry.clockIn!)
        : '--:--';
    final clockOutLabel = entry.clockOut != null
        ? DateFormat('hh:mm a').format(entry.clockOut!)
        : '--:--';
    final hoursLabel = entry.totalHours == entry.totalHours.roundToDouble()
        ? entry.totalHours.toInt().toString()
        : entry.totalHours.toStringAsFixed(1);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const StatusBadge(kind: StatusKind.completed),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.login,
                size: 14,
                color: AppColors.successGreenText,
              ),
              const SizedBox(width: 4),
              Text(clockInLabel, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              const Icon(Icons.logout, size: 14, color: AppColors.primaryMaroon),
              const SizedBox(width: 4),
              Text(clockOutLabel, style: const TextStyle(fontSize: 12)),
              const Spacer(),
              Text(
                '$hoursLabel Hrs',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryMaroon,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CorrectionRequestRow extends StatelessWidget {
  final AttendanceCorrectionRequest request;

  const _CorrectionRequestRow({required this.request});

  StatusKind get _statusKind {
    switch (request.status) {
      case CorrectionRequestStatus.pending:
        return StatusKind.pending;
      case CorrectionRequestStatus.approved:
        return StatusKind.approved;
      case CorrectionRequestStatus.rejected:
        return StatusKind.rejected;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('MMM d, yyyy').format(request.workDate);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'For $dateLabel',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusBadge(kind: _statusKind),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            request.reason,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (request.attachmentFileName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.attach_file,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.attachmentFileName!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (request.reviewerNote != null &&
              request.reviewerNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.statRedBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Reviewer note: ${request.reviewerNote}',
                style: const TextStyle(
                  color: AppColors.statRedIcon,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

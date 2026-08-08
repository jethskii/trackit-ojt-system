import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../models/teacher_attendance_record.dart';
import '../../models/teacher_correction_request.dart';
import '../../services/api_client.dart';
import '../../services/teacher_attendance_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/back_nav_header.dart';
import '../../widgets/common/empty_state_view.dart';
import '../../widgets/common/skeleton_list_tile.dart';

enum _AttendanceTab { records, requests }

/// Attendance -- Records (full clock-in/out log across all assigned
/// students) | Requests (correction requests, approve/reject after
/// verification). Approving/rejecting does not itself rewrite the
/// underlying attendance_records row -- there's no structured "requested
/// time" on a correction request, only a reason and an optional
/// attachment, so the decision is recorded as-is (see teacherAttendance.js).
class TeacherAttendanceScreen extends StatefulWidget {
  final TeacherAttendanceService service;
  final _AttendanceTab _initialTab;

  const TeacherAttendanceScreen({
    super.key,
    required this.service,
    bool startOnRequests = false,
  }) : _initialTab = startOnRequests ? _AttendanceTab.requests : _AttendanceTab.records;

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  late _AttendanceTab _tab = widget._initialTab;
  List<TeacherAttendanceRecord> _records = [];
  List<TeacherCorrectionRequest> _corrections = [];
  bool _loadingRecords = true;
  bool _loadingCorrections = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _loadCorrections();
  }

  Future<void> _loadRecords() async {
    setState(() => _loadingRecords = true);
    final records = await widget.service.getRecords();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loadingRecords = false;
    });
  }

  Future<void> _loadCorrections() async {
    setState(() => _loadingCorrections = true);
    final corrections = await widget.service.getCorrections();
    if (!mounted) return;
    setState(() {
      _corrections = corrections;
      _loadingCorrections = false;
    });
  }

  List<TeacherAttendanceRecord> get _filteredRecords {
    if (_query.isEmpty) return _records;
    final q = _query.toLowerCase();
    return _records.where((r) => r.studentName.toLowerCase().contains(q)).toList();
  }

  List<TeacherCorrectionRequest> get _filteredCorrections {
    if (_query.isEmpty) return _corrections;
    final q = _query.toLowerCase();
    return _corrections.where((r) => r.studentName.toLowerCase().contains(q)).toList();
  }

  Future<void> _reviewCorrection(TeacherCorrectionRequest request, bool approve) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve Correction' : 'Reject Correction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${request.studentName} -- ${DateFormat('MMM d, yyyy').format(request.workDate)}'),
            const SizedBox(height: 8),
            Text(request.reason, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Note to student (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: approve ? AppColors.successGreenText : AppColors.statRedIcon,
            ),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final note = controller.text.trim();
    await widget.service.reviewCorrection(
      correctionId: request.id,
      approve: approve,
      reviewerNote: note.isEmpty ? null : note,
    );
    await _loadCorrections();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(approve ? 'Correction approved.' : 'Correction rejected.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BackNavHeader(subtitle: 'Attendance'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: 'Records',
                      selected: _tab == _AttendanceTab.records,
                      onTap: () => setState(() => _tab = _AttendanceTab.records),
                    ),
                  ),
                  Expanded(
                    child: _SegmentButton(
                      label: 'Requests',
                      selected: _tab == _AttendanceTab.requests,
                      onTap: () => setState(() => _tab = _AttendanceTab.requests),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search Student...',
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
          Expanded(
            child: _tab == _AttendanceTab.records ? _buildRecords() : _buildRequests(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecords() {
    if (_loadingRecords) return const SkeletonList();
    final records = _filteredRecords;
    return RefreshIndicator(
      color: AppColors.primaryMaroon,
      onRefresh: _loadRecords,
      child: records.isEmpty
          ? ListView(
              children: const [
                EmptyStateView(
                  icon: Icons.fact_check_outlined,
                  title: 'No attendance records yet',
                  message: 'Clock-ins from your assigned students will show up here.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _RecordTile(record: records[index]),
            ),
    );
  }

  Widget _buildRequests() {
    if (_loadingCorrections) return const SkeletonList();
    final requests = _filteredCorrections;
    return RefreshIndicator(
      color: AppColors.primaryMaroon,
      onRefresh: _loadCorrections,
      child: requests.isEmpty
          ? ListView(
              children: const [
                EmptyStateView(
                  icon: Icons.rule_folder_outlined,
                  title: 'No correction requests',
                  message: 'Correction requests from your students will show up here.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _CorrectionTile(
                request: requests[index],
                onReview: (approve) => _reviewCorrection(requests[index], approve),
              ),
            ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final TeacherAttendanceRecord record;

  const _RecordTile({required this.record});

  String _formatTime(DateTime? time) => time == null ? '--:--' : DateFormat('h:mm a').format(time);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.background,
            backgroundImage: record.avatarUrl != null
                ? NetworkImage(ApiClient.resolveUrl(record.avatarUrl!))
                : null,
            child: record.avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.primaryMaroon, size: 18)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.studentName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(record.workDate),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatTime(record.clockIn)} - ${_formatTime(record.clockOut)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              if (record.hoursRendered != null)
                Text(
                  '${record.hoursRendered!.toStringAsFixed(1)} hrs',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CorrectionTile extends StatelessWidget {
  final TeacherCorrectionRequest request;
  final ValueChanged<bool> onReview;

  const _CorrectionTile({required this.request, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == CorrectionStatus.pending;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.studentName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
              _StatusPill(status: request.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEE, MMM d, yyyy').format(request.workDate),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(request.reason, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          if (request.attachmentFileName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.attach_file, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(request.attachmentFileName!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
          if (request.reviewerNote != null && request.reviewerNote!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Reviewer note: ${request.reviewerNote}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onReview(true),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.successGreenText,
                      side: const BorderSide(color: AppColors.successGreenText),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onReview(false),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statRedIcon,
                      side: const BorderSide(color: AppColors.statRedIcon),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final CorrectionStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      CorrectionStatus.pending => ('Pending', AppColors.statOrangeIcon),
      CorrectionStatus.approved => ('Approved', AppColors.successGreenText),
      CorrectionStatus.rejected => ('Rejected', AppColors.statRedIcon),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryMaroon : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

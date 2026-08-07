import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance.dart';
import '../../models/ojt_progress.dart';
import '../../services/api_client.dart';
import '../../services/attendance_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/location_helper.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/student/attendance_history_section.dart';
import '../../widgets/student/attendance_quick_actions.dart';
import '../../widgets/student/ojt_progress_card.dart';
import '../../widgets/student/today_attendance_card.dart';

class StudentAttendanceView extends StatefulWidget {
  final AttendanceService service;
  final OjtProgress initialProgress;
  final TodayAttendance initialAttendance;
  final List<AttendanceHistoryEntry> initialHistory;

  /// Pushes the Correction Request Form and returns the success message
  /// popped from it, if any (owned by AttendanceTabNavigator so the
  /// bottom nav stays visible).
  final Future<String?> Function() onOpenCorrectionRequest;
  final VoidCallback onOpenHistory;

  const StudentAttendanceView({
    super.key,
    required this.service,
    required this.initialProgress,
    required this.initialAttendance,
    this.initialHistory = const [],
    required this.onOpenCorrectionRequest,
    required this.onOpenHistory,
  });

  @override
  State<StudentAttendanceView> createState() => _StudentAttendanceViewState();
}

class _StudentAttendanceViewState extends State<StudentAttendanceView> {
  late TodayAttendance _attendance;
  late OjtProgress _progress;
  late List<AttendanceHistoryEntry> _history;
  late DateTime _now;
  bool _busy = false;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _attendance = widget.initialAttendance;
    _progress = widget.initialProgress;
    _history = widget.initialHistory;
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final results = await Future.wait([
      widget.service.getToday(),
      widget.service.getProgress(),
      widget.service.getHistory(),
    ]);
    if (!mounted) return;
    setState(() {
      _attendance = results[0] as TodayAttendance;
      _progress = results[1] as OjtProgress;
      _history = results[2] as List<AttendanceHistoryEntry>;
    });
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  // Clock In is the only action that spends an attempt (see
  // TodayAttendance.canClockOut -- clocking out is always free once a
  // session is open), so it's the only one that can trigger the
  // final-attempt warning before its normal confirmation.
  Future<bool> _confirmClockIn() async {
    final remaining = _attendance.attemptsRemaining;
    if (remaining <= 1) {
      final acknowledged = await _showConfirmDialog(
        title: '⚠️ Final Attempt for Today',
        message:
            'You only have 1 clocking attempt remaining today.\n\n'
            'Please make sure your Clock In action is correct before '
            'continuing. This will be your final attempt for today.',
        confirmLabel: 'Continue',
        confirmColor: AppColors.statOrangeIcon,
      );
      if (acknowledged != true) return false;
    }
    final confirmed = await _showConfirmDialog(
      title: 'Confirm Clock In',
      message:
          'Are you sure you want to clock in now?\n\n'
          'You have $remaining attempt${remaining == 1 ? '' : 's'} '
          'remaining today.',
      confirmLabel: 'Clock In',
      confirmColor: AppColors.primaryMaroon,
    );
    return confirmed == true;
  }

  Future<bool> _confirmClockOut() async {
    final remaining = _attendance.attemptsRemaining;
    final confirmed = await _showConfirmDialog(
      title: 'Confirm Clock Out',
      message:
          'Are you sure you want to clock out now?\n\n'
          'You have $remaining attempt${remaining == 1 ? '' : 's'} '
          'remaining today. Please make sure your attendance information '
          'is correct.',
      confirmLabel: 'Clock Out',
      confirmColor: AppColors.primaryMaroon,
    );
    return confirmed == true;
  }

  Future<void> _handleClockAction() async {
    if (_busy) return;
    final isClockIn = _attendance.canClockIn;
    if (!isClockIn && !_attendance.canClockOut) return;

    setState(() => _busy = true);
    try {
      final proceed = isClockIn ? await _confirmClockIn() : await _confirmClockOut();
      if (!proceed) return;
      if (!mounted) return;

      final position = await getCurrentPosition();
      final updated = isClockIn
          ? await widget.service.clockIn(
              latitude: position.latitude,
              longitude: position.longitude,
            )
          : await widget.service.clockOut(
              latitude: position.latitude,
              longitude: position.longitude,
            );
      final progress = await widget.service.getProgress();
      if (!mounted) return;
      final timeLabel = DateFormat(
        'hh:mm a',
      ).format(updated.clockOut ?? updated.clockIn ?? DateTime.now());
      setState(() {
        _attendance = updated;
        _progress = progress;
        _now = DateTime.now();
      });
      final remaining = updated.attemptsRemaining;
      final message = isClockIn
          ? 'Clock In recorded at $timeLabel. $remaining attempt'
                '${remaining == 1 ? '' : 's'} remaining today.'
          : 'Clock Out recorded at $timeLabel.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.successGreenText),
      );
    } on LocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.statRedIcon),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.statRedIcon),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleCorrectionRequest() async {
    final result = await widget.onOpenCorrectionRequest();
    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result), backgroundColor: AppColors.successGreenText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primaryMaroon,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppHeader(
                title: 'Attendance',
                subtitle: 'Monitor & Track Time Records',
              ),
              Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OjtProgressCard(progress: _progress),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TodayAttendanceCard(attendance: _attendance),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AttendanceQuickActions(
                  attendance: _attendance,
                  currentTime: _now,
                  onClockAction: _busy ? null : _handleClockAction,
                  onCorrectionRequest: _handleCorrectionRequest,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: AttendanceHistorySection(
                  history: _history,
                  onViewAll: widget.onOpenHistory,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

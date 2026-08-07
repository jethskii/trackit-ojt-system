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

  Future<void> _handleClockAction() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final position = await getCurrentPosition();
      final updated = _attendance.hasClockedIn
          ? await widget.service.clockOut(
              latitude: position.latitude,
              longitude: position.longitude,
            )
          : await widget.service.clockIn(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.hasClockedOut
                ? 'Clocked out at $timeLabel'
                : 'Clocked in at $timeLabel',
          ),
          backgroundColor: AppColors.successGreenText,
        ),
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

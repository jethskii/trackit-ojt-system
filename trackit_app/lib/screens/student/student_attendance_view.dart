import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance.dart';
import '../../models/ojt_progress.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common/app_header.dart';
import '../../widgets/student/attendance_history_section.dart';
import '../../widgets/student/attendance_quick_actions.dart';
import '../../widgets/student/ojt_progress_card.dart';
import '../../widgets/student/today_attendance_card.dart';

class StudentAttendanceView extends StatefulWidget {
  final OjtProgress progress;
  final TodayAttendance initialAttendance;
  final List<AttendanceHistoryEntry> history;

  const StudentAttendanceView({
    super.key,
    required this.progress,
    required this.initialAttendance,
    this.history = const [],
  });

  @override
  State<StudentAttendanceView> createState() => _StudentAttendanceViewState();
}

class _StudentAttendanceViewState extends State<StudentAttendanceView> {
  late TodayAttendance _attendance;
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _attendance = widget.initialAttendance;
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

  void _handleClockAction() {
    final now = DateTime.now();
    final timeLabel = DateFormat('hh:mm a').format(now);
    String? confirmation;

    setState(() {
      if (!_attendance.hasClockedIn) {
        _attendance = _attendance.copyWith(clockIn: now);
        confirmation = 'Clocked in at $timeLabel';
      } else if (!_attendance.hasClockedOut) {
        _attendance = _attendance.copyWith(clockOut: now);
        confirmation = 'Clocked out at $timeLabel';
      }
      _now = now;
    });

    if (confirmation != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(confirmation!),
          backgroundColor: AppColors.successGreenText,
        ),
      );
    }
  }

  void _handleCorrectionRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Correction Request Form is coming soon.')),
    );
  }

  void _handleViewAllHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance History is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
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
                child: OjtProgressCard(progress: widget.progress),
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
                onClockAction: _handleClockAction,
                onCorrectionRequest: _handleCorrectionRequest,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: AttendanceHistorySection(
                history: widget.history,
                onViewAll: _handleViewAllHistory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

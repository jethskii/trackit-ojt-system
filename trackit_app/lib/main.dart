import 'package:flutter/material.dart';
import 'models/attendance.dart';
import 'models/ojt_progress.dart';
import 'models/student.dart';
import 'screens/student/student_shell.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TRACKIT',
      theme: ThemeData(fontFamily: 'Roboto'),
      home: StudentShell(
        student: const Student(
          name: 'Way-Ar Sangngern',
          course: 'BSIT',
          section: '4E',
          companyName: 'GMMTV Company Limited',
        ),
        progress: OjtProgress(
          completedHours: 278,
          totalHours: 486,
          daysAttended: 35,
          estimatedCompletion: DateTime(2026, 10, 1),
          averageHoursPerDay: 8,
          weeklyAverageHours: 40,
          aheadOfSchedule: true,
        ),
        announcements: const [],
        todayAttendance: TodayAttendance(
          date: today,
          clockIn: DateTime(today.year, today.month, today.day, 8, 1),
        ),
        attendanceHistory: const [],
      ),
    );
  }
}

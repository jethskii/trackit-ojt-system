import 'package:flutter/material.dart';
import '../../services/teacher_classes_service.dart';
import '../../services/teacher_students_service.dart';
import 'teacher_student_detail_screen.dart';
import 'teacher_students_screen.dart';

/// Mirrors DocumentsTabNavigator: owns a nested Navigator so drilling
/// into a student's detail view keeps the bottom nav visible.
class TeacherStudentsTabNavigator extends StatefulWidget {
  final TeacherClassesService classesService;
  final TeacherStudentsService studentsService;

  const TeacherStudentsTabNavigator({
    super.key,
    required this.classesService,
    required this.studentsService,
  });

  @override
  State<TeacherStudentsTabNavigator> createState() =>
      _TeacherStudentsTabNavigatorState();
}

class _TeacherStudentsTabNavigatorState
    extends State<TeacherStudentsTabNavigator> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigatorKey.currentState?.maybePop();
      },
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          Widget page;
          if (settings.name != null && settings.name!.startsWith('/student/')) {
            final studentId = int.parse(settings.name!.substring('/student/'.length));
            page = TeacherStudentDetailScreen(
              studentId: studentId,
              studentsService: widget.studentsService,
            );
          } else {
            page = TeacherStudentsScreen(
              classesService: widget.classesService,
              studentsService: widget.studentsService,
              onOpenStudent: (studentId) =>
                  _navigatorKey.currentState?.pushNamed('/student/$studentId'),
            );
          }
          return MaterialPageRoute(builder: (_) => page, settings: settings);
        },
      ),
    );
  }
}

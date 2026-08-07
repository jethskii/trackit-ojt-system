import '../models/instructor_class.dart';
import 'api_client.dart';

abstract class TeacherClassesService {
  Future<List<InstructorClass>> getClasses();

  Future<InstructorClass> createClass({
    required String program,
    required String section,
    required String academicYear,
  });
}

class HttpTeacherClassesService implements TeacherClassesService {
  final ApiClient client;

  HttpTeacherClassesService(this.client);

  @override
  Future<List<InstructorClass>> getClasses() async {
    final response = await client.get('/api/teacher/classes');
    final rows = response['classes'] as List<dynamic>;
    return rows
        .map((row) => InstructorClass.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<InstructorClass> createClass({
    required String program,
    required String section,
    required String academicYear,
  }) async {
    final response = await client.post(
      '/api/teacher/classes',
      body: {'program': program, 'section': section, 'academicYear': academicYear},
    );
    return InstructorClass.fromJson(response['class'] as Map<String, dynamic>);
  }
}

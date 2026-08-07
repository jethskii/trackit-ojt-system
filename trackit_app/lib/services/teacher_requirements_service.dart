import '../models/custom_requirement_target.dart';
import '../models/teacher_custom_requirement_submission.dart';
import '../models/teacher_requirement_phase.dart';
import '../models/teacher_requirement_student_summary.dart';
import 'api_client.dart';

class TeacherStudentRequirements {
  final RequirementProgressSummary summary;
  final List<TeacherRequirementPhase> phases;
  final List<TeacherCustomRequirementSubmission> customRequirements;

  const TeacherStudentRequirements({
    required this.summary,
    required this.phases,
    required this.customRequirements,
  });
}

abstract class TeacherRequirementsService {
  Future<List<TeacherRequirementStudentSummary>> getStudents({
    String? search,
    String? status,
  });

  Future<TeacherStudentRequirements> getStudentRequirements(int studentId);

  Future<void> reviewSubmission({
    required String submissionId,
    required bool approve,
    String? remarks,
  });

  Future<void> reviewCustomSubmission({
    required String submissionId,
    required bool approve,
    String? remarks,
  });

  Future<List<CustomRequirementDefinition>> getCustomRequirements();

  Future<void> createCustomRequirement({
    required String title,
    required String description,
    DateTime? deadline,
    required List<int> classIds,
  });
}

class HttpTeacherRequirementsService implements TeacherRequirementsService {
  final ApiClient client;

  HttpTeacherRequirementsService(this.client);

  @override
  Future<List<TeacherRequirementStudentSummary>> getStudents({
    String? search,
    String? status,
  }) async {
    final query = <String, String>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null) 'status': status,
    };
    final uri = Uri(path: '/api/teacher/requirements/students', queryParameters: query);
    final response = await client.get(uri.toString());
    final rows = response['students'] as List<dynamic>;
    return rows
        .map((row) => TeacherRequirementStudentSummary.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TeacherStudentRequirements> getStudentRequirements(int studentId) async {
    final response = await client.get('/api/teacher/requirements/students/$studentId');
    final phases = (response['phases'] as List<dynamic>)
        .map((p) => TeacherRequirementPhase.fromJson(p as Map<String, dynamic>))
        .toList();
    final customRequirements = (response['customRequirements'] as List<dynamic>)
        .map((c) => TeacherCustomRequirementSubmission.fromJson(c as Map<String, dynamic>))
        .toList();
    return TeacherStudentRequirements(
      summary: RequirementProgressSummary.fromJson(response['summary'] as Map<String, dynamic>),
      phases: phases,
      customRequirements: customRequirements,
    );
  }

  @override
  Future<void> reviewSubmission({
    required String submissionId,
    required bool approve,
    String? remarks,
  }) async {
    await client.patch(
      '/api/teacher/requirements/submissions/$submissionId',
      body: {'decision': approve ? 'approved' : 'rejected', 'remarks': remarks},
    );
  }

  @override
  Future<void> reviewCustomSubmission({
    required String submissionId,
    required bool approve,
    String? remarks,
  }) async {
    await client.patch(
      '/api/teacher/requirements/custom-submissions/$submissionId',
      body: {'decision': approve ? 'approved' : 'rejected', 'remarks': remarks},
    );
  }

  @override
  Future<List<CustomRequirementDefinition>> getCustomRequirements() async {
    final response = await client.get('/api/teacher/requirements/custom');
    final rows = response['requirements'] as List<dynamic>;
    return rows
        .map((row) => CustomRequirementDefinition.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createCustomRequirement({
    required String title,
    required String description,
    DateTime? deadline,
    required List<int> classIds,
  }) async {
    await client.post(
      '/api/teacher/requirements/custom',
      body: {
        'title': title,
        'description': description,
        'deadline': deadline?.toIso8601String().substring(0, 10),
        'classIds': classIds,
      },
    );
  }
}

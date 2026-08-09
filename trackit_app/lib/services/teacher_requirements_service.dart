import 'dart:convert';

import '../models/custom_requirement_target.dart';
import '../models/teacher_custom_requirement_submission.dart';
import '../models/teacher_official_template.dart';
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
    List<int>? templateBytes,
    String? templateFileName,
    String? templateContentType,
  });

  Future<void> uploadCustomRequirementTemplate({
    required int requirementId,
    required List<int> templateBytes,
    required String templateFileName,
    required String templateContentType,
  });

  /// The Official Requirements catalog (phases + templates), for the
  /// "Manage Templates" screen -- not tied to any one student.
  Future<List<TeacherOfficialTemplatePhase>> getOfficialTemplates();

  Future<void> uploadOfficialTemplate({
    required int templateId,
    required List<int> templateBytes,
    required String templateFileName,
    required String templateContentType,
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
    List<int>? templateBytes,
    String? templateFileName,
    String? templateContentType,
  }) async {
    await client.postMultipart(
      '/api/teacher/requirements/custom',
      fieldName: 'template',
      fileBytes: templateBytes,
      fileName: templateFileName,
      contentType: templateContentType ?? 'application/octet-stream',
      fields: {
        'title': title,
        'description': description,
        if (deadline != null) 'deadline': deadline.toIso8601String().substring(0, 10),
        'classIds': jsonEncode(classIds),
      },
    );
  }

  @override
  Future<void> uploadCustomRequirementTemplate({
    required int requirementId,
    required List<int> templateBytes,
    required String templateFileName,
    required String templateContentType,
  }) async {
    await client.postMultipart(
      '/api/teacher/requirements/custom/$requirementId/template',
      fieldName: 'template',
      fileBytes: templateBytes,
      fileName: templateFileName,
      contentType: templateContentType,
    );
  }

  @override
  Future<List<TeacherOfficialTemplatePhase>> getOfficialTemplates() async {
    final response = await client.get('/api/teacher/requirements/templates');
    final rows = response['phases'] as List<dynamic>;
    return rows
        .map((row) => TeacherOfficialTemplatePhase.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> uploadOfficialTemplate({
    required int templateId,
    required List<int> templateBytes,
    required String templateFileName,
    required String templateContentType,
  }) async {
    await client.postMultipart(
      '/api/teacher/requirements/templates/$templateId/template',
      fieldName: 'template',
      fileBytes: templateBytes,
      fileName: templateFileName,
      contentType: templateContentType,
    );
  }
}

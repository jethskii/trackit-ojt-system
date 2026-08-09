import '../models/admin_instructor.dart';
import 'api_client.dart';

abstract class AdminInstructorsService {
  Future<List<AdminInstructorSummary>> getInstructors({String? search});

  Future<AdminInstructorDetail> getInstructorDetail(int instructorId, {String? academicYear});

  Future<AdminInstructorSummary> createInstructor({
    required String name,
    required String email,
    String? phone,
    String? department,
    String? position,
    DateTime? dateHired,
  });

  Future<void> updateInstructor({
    required int instructorId,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? position,
    DateTime? dateHired,
  });

  Future<void> revokeAccess(int instructorId);

  Future<void> reactivate(int instructorId);

  Future<String> regenerateActivationCode(int instructorId);
}

class HttpAdminInstructorsService implements AdminInstructorsService {
  final ApiClient client;

  HttpAdminInstructorsService(this.client);

  @override
  Future<List<AdminInstructorSummary>> getInstructors({String? search}) async {
    final query = <String, String>{
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri(path: '/api/admin/instructors', queryParameters: query);
    final response = await client.get(uri.toString());
    final rows = response['instructors'] as List<dynamic>;
    return rows
        .map((row) => AdminInstructorSummary.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminInstructorDetail> getInstructorDetail(
    int instructorId, {
    String? academicYear,
  }) async {
    final query = <String, String>{
      if (academicYear != null && academicYear.isNotEmpty) 'academicYear': academicYear,
    };
    final uri = Uri(path: '/api/admin/instructors/$instructorId', queryParameters: query);
    final response = await client.get(uri.toString());
    return AdminInstructorDetail.fromJson(response['instructor'] as Map<String, dynamic>);
  }

  @override
  Future<AdminInstructorSummary> createInstructor({
    required String name,
    required String email,
    String? phone,
    String? department,
    String? position,
    DateTime? dateHired,
  }) async {
    final response = await client.post(
      '/api/admin/instructors',
      body: {
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        if (department != null) 'department': department,
        if (position != null) 'position': position,
        if (dateHired != null) 'dateHired': dateHired.toIso8601String().substring(0, 10),
      },
    );
    return AdminInstructorSummary.fromJson(response['instructor'] as Map<String, dynamic>);
  }

  @override
  Future<void> updateInstructor({
    required int instructorId,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? position,
    DateTime? dateHired,
  }) async {
    await client.patch(
      '/api/admin/instructors/$instructorId',
      body: {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (department != null) 'department': department,
        if (position != null) 'position': position,
        if (dateHired != null) 'dateHired': dateHired.toIso8601String().substring(0, 10),
      },
    );
  }

  @override
  Future<void> revokeAccess(int instructorId) async {
    await client.patch('/api/admin/instructors/$instructorId/revoke');
  }

  @override
  Future<void> reactivate(int instructorId) async {
    await client.patch('/api/admin/instructors/$instructorId/reactivate');
  }

  @override
  Future<String> regenerateActivationCode(int instructorId) async {
    final response = await client.patch(
      '/api/admin/instructors/$instructorId/regenerate-code',
    );
    return response['activationCode'] as String;
  }
}

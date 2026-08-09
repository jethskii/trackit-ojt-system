import '../models/admin_class.dart';
import 'api_client.dart';

abstract class AdminClassesService {
  Future<List<AdminClassSummary>> getClasses({String? search, String? academicYear});

  Future<List<AdminAcademicYear>> getAcademicYears();

  Future<AdminClassSummary> createSection({
    required String program,
    required String section,
    required String academicYear,
  });

  Future<AdminClassDetail> getClassDetail(int classId);

  Future<String> regenerateActivationCode(int classId);

  Future<AdminImportResult> importStudents({
    required int classId,
    required List<int> fileBytes,
    required String fileName,
  });

  /// Real CSV bytes fetched over an authenticated request (not a plain
  /// browser navigation, which wouldn't carry the auth token) -- the
  /// caller hands these to a platform download helper.
  Future<RawFileResponse> exportClasses(List<int> classIds);
}

class HttpAdminClassesService implements AdminClassesService {
  final ApiClient client;

  HttpAdminClassesService(this.client);

  @override
  Future<List<AdminClassSummary>> getClasses({String? search, String? academicYear}) async {
    final query = <String, String>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (academicYear != null && academicYear.isNotEmpty) 'academicYear': academicYear,
    };
    final uri = Uri(path: '/api/admin/classes', queryParameters: query);
    final response = await client.get(uri.toString());
    final rows = response['classes'] as List<dynamic>;
    return rows
        .map((row) => AdminClassSummary.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AdminAcademicYear>> getAcademicYears() async {
    final response = await client.get('/api/admin/classes/academic-years');
    final rows = response['academicYears'] as List<dynamic>;
    return rows
        .map((row) => AdminAcademicYear.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AdminClassSummary> createSection({
    required String program,
    required String section,
    required String academicYear,
  }) async {
    final response = await client.post(
      '/api/admin/classes',
      body: {'program': program, 'section': section, 'academicYear': academicYear},
    );
    return AdminClassSummary.fromJson(response['class'] as Map<String, dynamic>);
  }

  @override
  Future<AdminClassDetail> getClassDetail(int classId) async {
    final response = await client.get('/api/admin/classes/$classId');
    return AdminClassDetail.fromJson(response['class'] as Map<String, dynamic>);
  }

  @override
  Future<String> regenerateActivationCode(int classId) async {
    final response = await client.patch('/api/admin/classes/$classId/regenerate-code');
    return response['activationCode'] as String;
  }

  @override
  Future<AdminImportResult> importStudents({
    required int classId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final response = await client.postMultipart(
      '/api/admin/classes/$classId/import-students',
      fieldName: 'file',
      fileBytes: fileBytes,
      fileName: fileName,
      contentType: 'text/csv',
    );
    return AdminImportResult.fromJson(response);
  }

  @override
  Future<RawFileResponse> exportClasses(List<int> classIds) async {
    final ids = classIds.join(',');
    return client.getBytes('/api/admin/classes/export?ids=$ids');
  }
}

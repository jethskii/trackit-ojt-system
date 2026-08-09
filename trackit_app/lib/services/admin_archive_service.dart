import '../models/admin_class.dart';
import '../models/archive.dart';
import 'api_client.dart';

abstract class AdminArchiveService {
  Future<List<ArchiveAcademicYear>> getAcademicYears();

  Future<List<AdminClassSummary>> getClasses({required String year, String? search});

  Future<ArchiveClassDetail> getClassDetail(int classId);

  Future<RawFileResponse> exportYear(String year, {required String format});
}

class HttpAdminArchiveService implements AdminArchiveService {
  final ApiClient client;

  HttpAdminArchiveService(this.client);

  @override
  Future<List<ArchiveAcademicYear>> getAcademicYears() async {
    final response = await client.get('/api/admin/archive/academic-years');
    final rows = response['academicYears'] as List<dynamic>;
    return rows
        .map((row) => ArchiveAcademicYear.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AdminClassSummary>> getClasses({required String year, String? search}) async {
    final query = <String, String>{
      'year': year,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri(path: '/api/admin/archive/classes', queryParameters: query);
    final response = await client.get(uri.toString());
    final rows = response['classes'] as List<dynamic>;
    return rows
        .map((row) => AdminClassSummary.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ArchiveClassDetail> getClassDetail(int classId) async {
    final response = await client.get('/api/admin/archive/classes/$classId');
    return ArchiveClassDetail.fromJson(response['class'] as Map<String, dynamic>);
  }

  @override
  Future<RawFileResponse> exportYear(String year, {required String format}) async {
    final uri = Uri(
      path: '/api/admin/archive/export',
      queryParameters: {'year': year, 'format': format},
    );
    return client.getBytes(uri.toString());
  }
}

import '../models/admin_overview.dart';
import 'api_client.dart';

abstract class AdminOverviewService {
  Future<AdminOverview> getOverview({required String academicYear});
}

class HttpAdminOverviewService implements AdminOverviewService {
  final ApiClient client;

  HttpAdminOverviewService(this.client);

  @override
  Future<AdminOverview> getOverview({required String academicYear}) async {
    final uri = Uri(
      path: '/api/admin/overview',
      queryParameters: {'academicYear': academicYear},
    );
    final response = await client.get(uri.toString());
    return AdminOverview.fromJson(response['overview'] as Map<String, dynamic>);
  }
}

import '../models/hte_company.dart';
import 'api_client.dart';

/// Repository-style interface so a real HTTP-backed implementation can be
/// dropped in later without touching any screen or widget.
abstract class HteDirectoryService {
  Future<List<HteCompany>> getCompanies();
}

class HttpHteDirectoryService implements HteDirectoryService {
  final ApiClient client;

  HttpHteDirectoryService(this.client);

  @override
  Future<List<HteCompany>> getCompanies() async {
    final response = await client.get('/api/hte-companies');
    final rows = response['companies'] as List<dynamic>;
    return rows
        .map((row) => HteCompany.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}

import '../models/hte_company.dart';
import '../models/hte_company_contact.dart';
import 'api_client.dart';

abstract class AdminHteCompaniesService {
  Future<List<HteCompany>> getCompanies();

  Future<HteCompany> createCompany({
    required String name,
    required String industry,
    required String location,
    required String address,
    required String email,
    String? website,
    DateTime? dateAccredited,
    required List<HteCompanyContact> contacts,
  });

  Future<HteCompany> updateCompany({
    required int id,
    required String name,
    required String industry,
    required String location,
    required String address,
    required String email,
    String? website,
    DateTime? dateAccredited,
    required List<HteCompanyContact> contacts,
  });

  Future<void> deleteCompany(int id);
}

class HttpAdminHteCompaniesService implements AdminHteCompaniesService {
  final ApiClient client;

  HttpAdminHteCompaniesService(this.client);

  Map<String, dynamic> _body({
    required String name,
    required String industry,
    required String location,
    required String address,
    required String email,
    String? website,
    DateTime? dateAccredited,
    required List<HteCompanyContact> contacts,
  }) {
    return {
      'name': name,
      'industry': industry,
      'location': location,
      'address': address,
      'email': email,
      'website': website,
      'dateAccredited': dateAccredited?.toIso8601String().split('T').first,
      'contacts': contacts.map((c) => c.toJson()).toList(),
    };
  }

  @override
  Future<List<HteCompany>> getCompanies() async {
    final response = await client.get('/api/admin/hte-companies');
    final rows = response['companies'] as List<dynamic>;
    return rows.map((row) => HteCompany.fromJson(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<HteCompany> createCompany({
    required String name,
    required String industry,
    required String location,
    required String address,
    required String email,
    String? website,
    DateTime? dateAccredited,
    required List<HteCompanyContact> contacts,
  }) async {
    final response = await client.post(
      '/api/admin/hte-companies',
      body: _body(
        name: name,
        industry: industry,
        location: location,
        address: address,
        email: email,
        website: website,
        dateAccredited: dateAccredited,
        contacts: contacts,
      ),
    );
    return HteCompany.fromJson(response['company'] as Map<String, dynamic>);
  }

  @override
  Future<HteCompany> updateCompany({
    required int id,
    required String name,
    required String industry,
    required String location,
    required String address,
    required String email,
    String? website,
    DateTime? dateAccredited,
    required List<HteCompanyContact> contacts,
  }) async {
    final response = await client.patch(
      '/api/admin/hte-companies/$id',
      body: _body(
        name: name,
        industry: industry,
        location: location,
        address: address,
        email: email,
        website: website,
        dateAccredited: dateAccredited,
        contacts: contacts,
      ),
    );
    return HteCompany.fromJson(response['company'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCompany(int id) async {
    await client.delete('/api/admin/hte-companies/$id');
  }
}

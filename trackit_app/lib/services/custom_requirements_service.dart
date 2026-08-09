import '../models/custom_requirement.dart';
import 'api_client.dart';

/// Additional Requirements -- instructor-created, targeted at the
/// student's class. Mirrors [OjtRequirementsService] but for the
/// separate custom_requirements source (see teacherRequirements.js's
/// "+ Add New Requirement" flow).
abstract class CustomRequirementsService {
  Future<List<CustomRequirement>> getRequirements();

  Future<List<CustomRequirement>> submitRequirement({
    required String requirementId,
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
  });
}

class HttpCustomRequirementsService implements CustomRequirementsService {
  final ApiClient client;

  HttpCustomRequirementsService(this.client);

  @override
  Future<List<CustomRequirement>> getRequirements() async {
    final response = await client.get('/api/custom-requirements');
    final rows = response['requirements'] as List<dynamic>;
    return rows
        .map((row) => CustomRequirement.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<CustomRequirement>> submitRequirement({
    required String requirementId,
    required List<int> fileBytes,
    required String fileName,
    required String contentType,
  }) async {
    await client.postMultipart(
      '/api/custom-requirements/$requirementId/submit',
      fieldName: 'file',
      fileBytes: fileBytes,
      fileName: fileName,
      contentType: contentType,
    );
    return getRequirements();
  }
}

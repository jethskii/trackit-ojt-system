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
    required String fileName,
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
    required String fileName,
  }) async {
    // No real file_picker plugin yet, same as OjtRequirementsService --
    // the server accepts a JSON { fileName } submission.
    await client.post(
      '/api/custom-requirements/$requirementId/submit',
      body: {'fileName': fileName},
    );
    return getRequirements();
  }
}

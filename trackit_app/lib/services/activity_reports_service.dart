import '../models/weekly_accomplishment_report.dart';
import 'api_client.dart';

/// Weekly Accomplishment Report (AR) slots -- one recurring upload per OJT
/// week, generated server-side from the student's OJT Start Date through
/// the current week (see routes/activityReports.js). Purely a
/// record/compilation: no hours field, no link to attendance.
abstract class ActivityReportsService {
  Future<List<WeeklyAccomplishmentReport>> getReports();

  Future<List<WeeklyAccomplishmentReport>> submitReport({
    required int weekNumber,
    required String description,
    required List<String> attachments,
  });
}

class HttpActivityReportsService implements ActivityReportsService {
  final ApiClient client;

  HttpActivityReportsService(this.client);

  @override
  Future<List<WeeklyAccomplishmentReport>> getReports() async {
    final response = await client.get('/api/activity-reports');
    final rows = response['reports'] as List<dynamic>;
    return rows
        .map(
          (row) => WeeklyAccomplishmentReport.fromJson(
            row as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<List<WeeklyAccomplishmentReport>> submitReport({
    required int weekNumber,
    required String description,
    required List<String> attachments,
  }) async {
    await client.post(
      '/api/activity-reports/$weekNumber/submit',
      body: {'description': description, 'attachments': attachments},
    );
    return getReports();
  }
}

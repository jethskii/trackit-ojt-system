import 'package:intl/intl.dart';
import '../models/activity_report.dart';
import 'api_client.dart';

abstract class ActivityReportsService {
  Future<List<ActivityReport>> getReports();
  Future<ActivityReport> createReport(ActivityReport report);
  Future<ActivityReport> updateReport(ActivityReport report);
}

class HttpActivityReportsService implements ActivityReportsService {
  final ApiClient client;

  HttpActivityReportsService(this.client);

  Map<String, dynamic> _toBody(ActivityReport report) {
    return {
      'title': report.title,
      'reportDate': DateFormat('yyyy-MM-dd').format(report.date),
      'hoursRendered': report.hoursRendered,
      'description': report.description,
      'status': ActivityReport.statusToDb(report.status),
      'attachments': report.attachments,
    };
  }

  @override
  Future<List<ActivityReport>> getReports() async {
    final response = await client.get('/api/activity-reports');
    final rows = response['reports'] as List<dynamic>;
    return rows
        .map((row) => ActivityReport.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ActivityReport> createReport(ActivityReport report) async {
    final response = await client.post(
      '/api/activity-reports',
      body: _toBody(report),
    );
    return ActivityReport.fromJson(response['report'] as Map<String, dynamic>);
  }

  @override
  Future<ActivityReport> updateReport(ActivityReport report) async {
    final response = await client.put(
      '/api/activity-reports/${report.id}',
      body: _toBody(report),
    );
    return ActivityReport.fromJson(response['report'] as Map<String, dynamic>);
  }
}

class MockActivityReportsService implements ActivityReportsService {
  final List<ActivityReport> _reports = [
    ActivityReport(
      id: 'report-1',
      title: 'Week 1 Activity Report',
      date: DateTime.now().subtract(const Duration(days: 7)),
      company: 'GMMTV Company Limited',
      hoursRendered: 40,
      description: 'Onboarding, orientation, and initial team assignments.',
      status: ActivityReportStatus.approved,
    ),
    ActivityReport(
      id: 'report-2',
      title: 'Week 2 Activity Report',
      date: DateTime.now().subtract(const Duration(days: 1)),
      company: 'GMMTV Company Limited',
      hoursRendered: 40,
      description: 'Worked on the internal content scheduling tool.',
      status: ActivityReportStatus.submitted,
    ),
  ];

  @override
  Future<List<ActivityReport>> getReports() async {
    return List.unmodifiable(_reports);
  }

  @override
  Future<ActivityReport> createReport(ActivityReport report) async {
    _reports.insert(0, report);
    return report;
  }

  @override
  Future<ActivityReport> updateReport(ActivityReport report) async {
    final index = _reports.indexWhere((r) => r.id == report.id);
    if (index != -1) {
      _reports[index] = report;
    }
    return report;
  }
}

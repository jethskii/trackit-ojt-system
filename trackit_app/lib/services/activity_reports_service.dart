import '../models/activity_report.dart';

abstract class ActivityReportsService {
  Future<List<ActivityReport>> getReports();
  Future<ActivityReport> createReport(ActivityReport report);
  Future<ActivityReport> updateReport(ActivityReport report);
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

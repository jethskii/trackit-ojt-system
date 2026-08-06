import '../models/hte_company.dart';

/// Repository-style interface so a real HTTP-backed implementation can be
/// dropped in later without touching any screen or widget.
abstract class HteDirectoryService {
  Future<List<HteCompany>> getCompanies();
}

class MockHteDirectoryService implements HteDirectoryService {
  final List<HteCompany> _companies = const [
    HteCompany(
      id: 'hte-1',
      name: 'GMMTV Company Limited',
      industry: 'Media & Entertainment',
      address: 'Bangkok, Thailand',
      availablePositions: 3,
      email: 'careers@gmmtv.com',
      phone: '+66 2 111 2222',
      website: 'https://gmmtv.com',
      description:
          'A leading media production company specializing in digital '
          'content, broadcasting, and artist management.',
      availableSlots: 5,
    ),
    HteCompany(
      id: 'hte-2',
      name: 'Accenture Philippines',
      industry: 'Information Technology',
      address: 'San Pablo City, Laguna',
      availablePositions: 10,
      email: 'internship@accenture.com',
      phone: '+63 2 8988 5000',
      website: 'https://accenture.com',
      description:
          'Global professional services company offering IT and consulting '
          'internship programs for computing students.',
      availableSlots: 12,
    ),
    HteCompany(
      id: 'hte-3',
      name: 'San Pablo City Hall - IT Department',
      industry: 'Government',
      address: 'San Pablo City, Laguna',
      availablePositions: 4,
      email: 'it@sanpablocity.gov.ph',
      phone: '+63 49 562 1234',
      description:
          'Local government IT department handling systems, networks, and '
          'digital services for the city.',
      availableSlots: 4,
    ),
    HteCompany(
      id: 'hte-4',
      name: 'Innodata Philippines',
      industry: 'Business Process Outsourcing',
      address: 'Calamba, Laguna',
      availablePositions: 6,
      email: 'careers@innodata.com',
      phone: '+63 49 545 6789',
      website: 'https://innodata.com',
      description:
          'BPO company providing data engineering, annotation, and AI '
          'training data services.',
      availableSlots: 8,
    ),
  ];

  @override
  Future<List<HteCompany>> getCompanies() async {
    return List.unmodifiable(_companies);
  }
}

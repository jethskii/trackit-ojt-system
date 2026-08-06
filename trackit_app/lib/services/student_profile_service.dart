import '../models/hte_company.dart';
import '../models/staff_contact.dart';
import '../models/student_profile.dart';

abstract class StudentProfileService {
  Future<StudentProfile> getProfile();

  /// Real photo upload needs image_picker/cropper + a storage backend,
  /// neither of which exist yet -- this just updates the in-memory
  /// profile so the rest of the app has a single place to swap in a real
  /// implementation later.
  Future<StudentProfile> updateAvatar(String avatarUrl);
}

class MockStudentProfileService implements StudentProfileService {
  StudentProfile _profile = const StudentProfile(
    fullName: 'Way-Ar Sangngern',
    studentNumber: '21-00456',
    course: 'BS Information Technology',
    yearLevel: '4th Year',
    section: 'Section F',
    school: 'Dalubhasaan ng Lungsod ng San Pablo',
    email: 'wayar.sangngern@dlsp.edu.ph',
    mobileNumber: '+63 917 123 4567',
    adviser: StaffContact(
      name: 'Gawin Caskey',
      role: 'OJT Adviser',
      email: 'gawin.caskey@dlsp.edu.ph',
      phone: '+63 917 555 0101',
    ),
    company: HteCompany(
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
    supervisor: StaffContact(
      name: 'Ayden Sng',
      role: 'HR Supervisor',
      email: 'ayden.sng@gmmtv.com',
      phone: '+66 2 111 2233',
    ),
  );

  @override
  Future<StudentProfile> getProfile() async => _profile;

  @override
  Future<StudentProfile> updateAvatar(String avatarUrl) async {
    _profile = _profile.copyWith(avatarUrl: avatarUrl);
    return _profile;
  }
}

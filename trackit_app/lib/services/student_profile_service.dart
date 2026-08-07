import '../models/company_details.dart';
import '../models/staff_contact.dart';
import '../models/student_profile.dart';
import 'api_client.dart';

abstract class StudentProfileService {
  Future<StudentProfile> getProfile();

  /// Real photo upload needs image_picker/cropper, neither of which are
  /// wired up in the UI yet -- this just updates the in-memory profile so
  /// the rest of the app has a single place to swap in a real
  /// implementation later.
  Future<StudentProfile> updateAvatar(String avatarUrl);

  /// Saves the student's self-reported company details (Confirm Company
  /// Details step). Also sets [StudentProfile.supervisor], since that form
  /// collects the supervisor's name and contact number together with the
  /// company info.
  Future<StudentProfile> submitCompanyDetails(CompanyDetails details);
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
    // Null until the student completes the Confirm Company Details step.
    company: null,
    supervisor: null,
  );

  @override
  Future<StudentProfile> getProfile() async => _profile;

  @override
  Future<StudentProfile> updateAvatar(String avatarUrl) async {
    _profile = _profile.copyWith(avatarUrl: avatarUrl);
    return _profile;
  }

  @override
  Future<StudentProfile> submitCompanyDetails(CompanyDetails details) async {
    _profile = _profile.withCompanyDetails(details);
    return _profile;
  }
}

class HttpStudentProfileService implements StudentProfileService {
  final ApiClient client;

  HttpStudentProfileService(this.client);

  @override
  Future<StudentProfile> getProfile() async {
    final response = await client.get('/api/profile');
    return StudentProfile.fromJson(response['profile'] as Map<String, dynamic>);
  }

  @override
  Future<StudentProfile> updateAvatar(String avatarUrl) async {
    // Not called from the UI yet -- there's no image_picker integration
    // to produce real bytes for POST /api/profile/avatar (a multipart
    // upload) to receive. Once that's wired up, this should take the
    // picked image's bytes instead of a pre-existing URL string.
    return getProfile();
  }

  @override
  Future<StudentProfile> submitCompanyDetails(CompanyDetails details) async {
    await client.post('/api/profile/company', body: details.toJson());
    return getProfile();
  }
}

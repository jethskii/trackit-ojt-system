/// A person connected to the student's OJT (adviser or HR supervisor).
class StaffContact {
  final String name;
  final String role;
  final String email;
  final String phone;
  final String? photoUrl;

  const StaffContact({
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    this.photoUrl,
  });
}

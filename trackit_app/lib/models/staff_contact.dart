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

  factory StaffContact.fromJson(Map<String, dynamic> json) {
    return StaffContact(
      name: json['name'] as String,
      role: json['role'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
